#include <assert.h>
#include <iostream>
//#include <cuda_runtime.h>

#include <cudaUtils.h>

// Function to check any CUDA runtime API results
cudaError_t checkCuda(cudaError_t result)//inline 
{
    #if defined(DEBUG) || defined(_DEBUG)
        if (result != cudaSuccess) {
        std::cout <<  "CUDA Runtime Error: " << cudaGetErrorString(result)<< std::endl;
        assert(result == cudaSuccess);
        }
    #endif
        return result;
}

void streamDestroy(cudaStream_t *stream, int nStreams){
    for (int i = 0; i < nStreams; ++i)
        checkCuda(cudaStreamDestroy(stream[i]));
    delete []stream;
}

cudaStream_t* streamCreate(int nStreams){
    cudaStream_t *stream=new cudaStream_t[nStreams];
    for (int i = 0; i < nStreams; ++i)
        checkCuda(cudaStreamCreate(&stream[i]));
    return stream;
}