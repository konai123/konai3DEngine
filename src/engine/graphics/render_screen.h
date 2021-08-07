//
// Created by korona on 2021-06-27.
//

#pragma once

#include <utility>

#include "src/engine/core/pool.hpp"
#include "src/engine/graphics/macros.h"
#include "src/engine/graphics/device_com.h"
#include "src/engine/graphics/resource_descriptor_heap.h"
#include "src/engine/graphics/render_object.h"
#include "src/engine/graphics/shader_types.h"

_START_ENGINE
class RenderScreen{
public:
    RenderScreen (
            std::shared_ptr<DeviceCom> device,
            std::shared_ptr<ResourceDescriptorHeap> resource_heap_pool,
            UINT width,
            UINT height,
            DirectX::XMVECTORF32 _clear_color
    );
    virtual ~RenderScreen();

public:
    bool AddRenderObject(RenderObject* renderObject);
    bool UnRegisterRenderObject(UINT objID);
    RenderObject *GetRenderObject(UINT objID);
    std::vector<RenderObject *> GetRenderObjects();

    D3D12_VIEWPORT *GetViewPort();
    D3D12_RECT *GetScissorRect();
    ID3D12Resource *GetRenderTargetResource();
    ID3D12Resource *GetDepthStencilResource();

    HeapDescriptorHandle *GetRenderTargetHeapDesc();
    HeapDescriptorHandle *GetShaderResourceHeapDesc();
    HeapDescriptorHandle *GetDepthStencilHeapDesc();

    bool Resize(UINT width, UINT height);
    UINT Size();

public:
    float4x4 ViewMatrix;
    float4x4 InverseViewMatrix;
    float4x4 ProjectionMatrix;

private:
    bool CreateRenderTargets(bool isRecreation, UINT width, UINT height);
    bool CreateRenderTargetResourceAndView(bool isRecreation, UINT width, UINT height);
    bool CreateDepthStencilBufferAndView(bool isRecreation, UINT width, UINT height);

private:
    std::shared_ptr<DeviceCom> _device;
    std::shared_ptr<ResourceDescriptorHeap> _resource_heap;
    std::unordered_map<UINT, RenderObject*> _render_objects;

    Microsoft::WRL::ComPtr<ID3D12Resource> _dsv_buffer;
    Microsoft::WRL::ComPtr<ID3D12Resource> _render_target;

    HeapDescriptorHandle _render_target_view;
    HeapDescriptorHandle _shader_view;
    HeapDescriptorHandle _depth_stencil_view;

    DirectX::XMVECTORF32 _clear_color;
    UINT _width;
    UINT _height;
    D3D12_VIEWPORT _viewport;
    D3D12_RECT _scissor_rect;
};
_END_ENGINE
