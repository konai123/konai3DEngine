#ifndef PATHTRACE_HLSL
#define PATHTRACE_HLSL

#include <common.hlsli>
#include <global_root_args.hlsli>
#include <shader_table.hlsli>
#include <vertex.hlsli>
#include <sampler.hlsli>
#include <math.hlsli>
#include <bsdf.hlsli>

float4 RayColor(RayPayload raypay, uint maxDepth) {
    float4 outColor = float4(1.0f, 1.0f, 1.0f, 1.0f);

    for (uint i = 0; i < maxDepth; i++) {
        RayDesc r;
        r =  raypay.Ray(0.001f, 100000.0f);
        TraceRay(
                gRaytracingAccelerationStructure,
                RAY_FLAG_NONE,
                0xffffffff,
                0,   /*Hit Gourp Index*/
                1,   /*Ray Stride*/
                0,   /*Miss Shader Index*/
                r,
                raypay);

        outColor *= raypay.HitColor / raypay.Pdf;
        if (raypay.T < 0.0f) {
            if (i >= maxDepth - 1) {
                return float4(0.0f, 0.0f, 0.0f, 1.0f);
            }
            break;
        }
    }

    return float4(outColor.xyz, 1.0f);
}

[shader("raygeneration")]
void RayGen()
{
    uint2 LaunchIndex = DispatchRaysIndex().xy;
    uint2 LaunchDimensions = DispatchRaysDimensions().xy;
    uint seed = uint(LaunchIndex.x * (5555) + LaunchIndex.y * uint(20328) + uint(gTotalFrameCount) * uint(24023));

    const uint sampleCount = 4;

    //Camera Position
    float3 outColor = float3(0.f, 0.f, 0.f);
    for (uint i = 0; i < sampleCount; i++)
    {
        float2 r = float2(RandomFloat01(seed), RandomFloat01(seed));
        float2 uv = (float2(LaunchIndex) + (r - 0.5)) / float2(LaunchDimensions);
        float2 ndc = uv * float2(2,-2) + float2(-1, +1);
        RayPayload raypay = gCamera.GetRayPayload(ndc, seed);
        outColor += RayColor(raypay, 15).xyz;
    }

    outColor.r = isnan(outColor.r) ? 0.0f : outColor.r;
    outColor.g = isnan(outColor.g) ? 0.0f : outColor.g;
    outColor.b = isnan(outColor.b) ? 0.0f : outColor.b;

    RWTexture2D<float4> output = gRTOutputs[gRenderTargetIdx];
    outColor /= float(sampleCount);
    outColor = sqrt(outColor);

    if (gIntegrationCount > 1) {
        outColor = lerp(outColor.xyz, float3(output[LaunchIndex.xy].xyz), 1.f/float(gIntegrationCount));
    }

    output[LaunchIndex.xy] = float4(outColor.xyz, 1.0f);
}

[shader("closesthit")]
void ClosestHit(inout RayPayload payload, Attributes attrib)
{
    payload.T = RayTCurrent();

    unsigned int idx0 = IndexBuffer[PrimitiveIndex() * 3 + 0];
    unsigned int idx1 = IndexBuffer[PrimitiveIndex() * 3 + 1];
    unsigned int idx2 = IndexBuffer[PrimitiveIndex() * 3 + 2];

    Vertex vtx0 = VertexBuffer[idx0];
    Vertex vtx1 = VertexBuffer[idx1];
    Vertex vtx2 = VertexBuffer[idx2];

	float3 barycentrics = float3((1.0f - attrib.uv.x - attrib.uv.y), attrib.uv.x, attrib.uv.y);
    Vertex vertex = GetVertexAttributes(vtx0, vtx1, vtx2, barycentrics);

    Material mat = gMaterials[gMaterialIdx];
    int diffuseTextureIndex = mat.DiffuseTextureIndex;
    Texture2D diffuse = gTexture2DTable[diffuseTextureIndex];
    float3 color = diffuse.SampleLevel(gSamPointClamp, vertex.TexCoord, 0.0f).rgb;
    float3 worldNormal = normalize(mul(vertex.Normal, (float3x3)WorldToObject3x4()));

    //BSDF Init
    BSDF bsdf;
    bsdf.Init(mat.MaterialType, color, mat.Fuzz, mat.RefractIndex);

    float3 outDirection;
    float3 outAttenuation;
    float pdf;
    if (!bsdf.Scatter(payload.Direction, worldNormal, outDirection, outAttenuation, pdf, payload.Seed)) {
        payload.HitColor = float4(0.0f, 0.0f, 0.0f, 0.0f);
        payload.T = -1.0f;
        payload.Pdf = 1.0f;
        return;
    }

    payload.Pdf = pdf;
    payload.Origin = payload.At();
    payload.Direction = normalize(outDirection);
	payload.HitColor = float4(outAttenuation.xyz, 1.0f);
}

[shader("miss")]
void Miss(inout RayPayload payload)
{
    float t = 0.5f*(WorldRayDirection().y + 1.0f);
    payload.HitColor = (1.0f-t)*float4(1.0f, 1.0f, 1.0f, 1.0f) + t*float4(0.5f, 0.7f, 1.0f, 1.0f);
    payload.Pdf = 1.0f;
    payload.T = -1.0f;
}
#endif