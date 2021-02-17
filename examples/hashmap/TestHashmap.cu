#include <stdgpu/iterator.h>  // device_begin, device_end
#include <stdgpu/memory.h>    // createDeviceArray, destroyDeviceArray
#include <stdgpu/platform.h>  // STDGPU_HOST_DEVICE
#include <thrust/copy.h>
#include <thrust/reduce.h>
#include <thrust/sequence.h>

#include <iostream>
#include <stdgpu/unordered_map.cuh>  // stdgpu::unordered_map

#include "open3d/core/hashmap/Hashmap.h"
#include "open3d/utility/Console.h"
#include "open3d/utility/Timer.h"

__global__ void insert_numbers(const int* d_keys,
                               const int* d_values,
                               const stdgpu::index_t n,
                               stdgpu::unordered_map<int, int> map) {
    stdgpu::index_t i =
            static_cast<stdgpu::index_t>(blockIdx.x * blockDim.x + threadIdx.x);

    if (i >= n) return;
    map.emplace(d_keys[i], d_values[i]);
}

__global__ void find_numbers(const int* d_keys,
                             int* d_values,
                             const stdgpu::index_t n,
                             stdgpu::unordered_map<int, int> map) {
    stdgpu::index_t i =
            static_cast<stdgpu::index_t>(blockIdx.x * blockDim.x + threadIdx.x);

    if (i >= n) return;
    d_values[i] = map.find(d_keys[i])->second;
}

int main(int argc, char** argv) {
    //
    // EXAMPLE DESCRIPTION
    // -------------------
    // This example demonstrates how stdgpu::unordered_map is used to compute a
    // duplicate-free set of numbers.
    //
    using namespace open3d;

    stdgpu::index_t n =
            utility::GetProgramOptionAsInt(argc, argv, "--n", 10000);
    int runs = utility::GetProgramOptionAsInt(argc, argv, "--runs", 1000);

    // Ours
    core::Tensor t_keys = core::Tensor::Arange(0, n, 1, core::Dtype::Int32,
                                               core::Device("CUDA:0"));
    core::Tensor t_values = core::Tensor::Arange(0, n, 1, core::Dtype::Int32,
                                                 core::Device("CUDA:0"));

    // Warm up
    core::Device device("CUDA:0");
    {
        core::Hashmap hashmap(n, core::Dtype::Int32, core::Dtype::Int32,
                              core::SizeVector{1}, core::SizeVector{1}, device);
        core::Tensor t_addrs({n}, core::Dtype::Int32, device);
        core::Tensor t_masks({n}, core::Dtype::Bool, device);

        hashmap.Insert(t_keys, t_values, t_addrs, t_masks);
        hashmap.Find(t_keys, t_addrs, t_masks);
        cudaDeviceSynchronize();
    }

    utility::Timer timer;

    double insert_time = 0;
    double find_time = 0;
    for (int i = 0; i < runs; ++i) {
        core::Hashmap hashmap(n, core::Dtype::Int32, core::Dtype::Int32,
                              core::SizeVector{1}, core::SizeVector{1}, device);
        core::Tensor t_addrs({n}, core::Dtype::Int32, device);
        core::Tensor t_masks({n}, core::Dtype::Bool, device);

        timer.Start();
        hashmap.Insert(t_keys, t_values, t_addrs, t_masks);
        cudaDeviceSynchronize();
        timer.Stop();
        insert_time += timer.GetDuration();

        timer.Start();
        hashmap.Find(t_keys, t_addrs, t_masks);
        cudaDeviceSynchronize();
        timer.Stop();
        find_time += timer.GetDuration();

        if (hashmap.Size() != n) {
            utility::LogError("ours: incorrect insertion");
        }
    }
    utility::LogInfo("ours takes {} on average for insertion",
                     insert_time / runs);
    utility::LogInfo("ours takes {} on average for query", find_time / runs);

    // stdgpu
    int* d_keys = createDeviceArray<int>(n);
    thrust::sequence(stdgpu::device_begin(d_keys), stdgpu::device_end(d_keys),
                     0);
    int* d_values = createDeviceArray<int>(n);
    thrust::sequence(stdgpu::device_begin(d_values),
                     stdgpu::device_end(d_values), 0);
    insert_time = 0;
    find_time = 0;
    for (int i = 0; i < runs; ++i) {
        stdgpu::unordered_map<int, int> map =
                stdgpu::unordered_map<int, int>::createDeviceObject(n);
        stdgpu::index_t threads = 128;
        stdgpu::index_t blocks = (n + threads - 1) / threads;

        timer.Start();
        insert_numbers<<<static_cast<unsigned int>(blocks),
                         static_cast<unsigned int>(threads)>>>(d_keys, d_values,
                                                               n, map);
        cudaDeviceSynchronize();
        timer.Stop();
        insert_time += timer.GetDuration();

        timer.Start();
        find_numbers<<<static_cast<unsigned int>(blocks),
                       static_cast<unsigned int>(threads)>>>(d_keys, d_values,
                                                             n, map);
        cudaDeviceSynchronize();
        timer.Stop();
        find_time += timer.GetDuration();

        if (map.size() != n) {
            utility::LogError("stdgpu: incorrect insertion");
        }

        stdgpu::unordered_map<int, int>::destroyDeviceObject(map);
    }
    utility::LogInfo("stdgpu takes {} on average for insertion",
                     insert_time / runs);
    utility::LogInfo("stdgpu takes {} on average for query", find_time / runs);
    destroyDeviceArray<int>(d_keys);
    destroyDeviceArray<int>(d_values);
}
