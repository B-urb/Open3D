// ----------------------------------------------------------------------------
// -                        Open3D: www.open3d.org                            -
// ----------------------------------------------------------------------------
// The MIT License (MIT)
//
// Copyright (c) 2018 www.open3d.org
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in
// all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
// FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS
// IN THE SOFTWARE.
// ----------------------------------------------------------------------------

#pragma once

// Implementation for the CPU hashmap. Separated from HashmapCPU.h for brevity.

#include "open3d/core/hashmap/CPU/HashmapCPU.h"

namespace open3d {
namespace core {

template <typename Hash, typename KeyEq>
std::shared_ptr<CPUHashmap<Hash, KeyEq>> CreateTemplateCPUHashmap(
        size_t init_buckets,
        size_t init_capacity,
        size_t dsize_key,
        size_t dsize_value,
        const Device& device) {
    return std::make_shared<CPUHashmap<Hash, KeyEq>>(
            init_buckets, init_capacity, dsize_key, dsize_value, device);
}
}  // namespace core
}  // namespace open3d