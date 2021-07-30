//
// Created by korona on 2021-06-28.
//

#ifndef KONAI3D_SAMPLER_H
#define KONAI3D_SAMPLER_H

#include <utility>

#include "src/engine/graphics/device_com.h"
#include "src/engine/graphics/resource_descriptor_heap.h"

_START_ENGINE
class Sampler {
public:
    Sampler(std::shared_ptr<DeviceCom> device, std::shared_ptr<ResourceDescriptorHeap> resource_heap_pool);
    Sampler(const Sampler &) = delete;
    Sampler(Sampler &&) noexcept = default;
    Sampler &operator=(const Sampler &) = delete;
    Sampler &operator=(Sampler &&) noexcept = default;

    virtual ~Sampler();

public:
    bool SetSamplerDesc(D3D12_SAMPLER_DESC desc);
    HeapDescriptor *GetHeapDescriptor();

private:
    std::shared_ptr<DeviceCom> _device;
    std::shared_ptr<ResourceDescriptorHeap> _resource_heap;
    HeapDescriptor _heap_desc;
};

_END_ENGINE

#endif //KONAI3D_SAMPLER_H
