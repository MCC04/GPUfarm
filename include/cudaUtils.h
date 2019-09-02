#include <cuda_runtime.h>
#include <stdlib.h>
#include <assert.h> 

extern cudaDeviceProp prop; //queste robbe qua mi sa che è meglio levarle


//CUDA API error checking
#define gpuErrchk(ans) { gpuAssert((ans), __FILE__, __LINE__); }
void gpuAssert(cudaError_t code, const char *file, int line);

//CUDA streams/events utilities
void streamCreate(cudaStream_t * strms, int nStreams);
void streamDestroy(cudaStream_t *stream,int nStreams);
void createAndStartEvent(cudaEvent_t *startEvent, cudaEvent_t *stopEvent);
float endEvent(cudaEvent_t *startEvent, cudaEvent_t *stopEvent);

