#include <iostream>
#include <cudaUtils.h>

// Function to check any CUDA runtime API results
#define gpuErrchk(ans) { gpuAssert((ans), __FILE__, __LINE__); }
inline void gpuAssert(cudaError_t code, const char *file, int line)
{
    if (code != cudaSuccess) {
        std::cout <<  "CUDA Runtime Error: " << cudaGetErrorString(code)
                <<", "<< file <<", "<< line <<std::endl;
        assert(code == cudaSuccess);
    }
}


void streamDestroy(cudaStream_t *stream, int nStreams){
    for (int i = 0; i < nStreams; ++i)
        gpuErrchk(cudaStreamDestroy(stream[i]));
}


void streamCreate(cudaStream_t *streams, int nStreams){
    for (int i = 0; i < nStreams; ++i)
        gpuErrchk( cudaStreamCreate(&streams[i]) );
}


void createAndStartEvent(cudaEvent_t *startEvent, cudaEvent_t *stopEvent){
    gpuErrchk( cudaEventCreate(startEvent) );
    gpuErrchk( cudaEventCreate(stopEvent) );
    gpuErrchk( cudaEventRecord(*startEvent,0) );
}


float endEvent(cudaEvent_t *startEvent, cudaEvent_t *stopEvent){
    float ms = 0.0f;
    gpuErrchk( cudaEventRecord(*stopEvent, 0) );
    gpuErrchk( cudaEventSynchronize(*stopEvent) );
    gpuErrchk( cudaEventElapsedTime(&ms, *startEvent, *stopEvent) );
    return ms;
}