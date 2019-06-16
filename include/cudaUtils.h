#include <cuda_runtime.h>
#include <iostream>
#include <math.h>
#include <stdlib.h>
#include <assert.h> 
#include <cstdlib>
#include <algorithm>
#include <ctime>
#include <vector>
#include <future>
#include <iterator>

extern cudaDeviceProp prop;
extern int BLOCK;
extern int GRID;
extern int GRIDx;
extern int GRIDy;

//cudaError_t checkCuda(cudaError_t result);
#define gpuErrchk(ans) { gpuAssert((ans), __FILE__, __LINE__); }
void gpuAssert(cudaError_t code, const char *file, int line);
//cudaStream_t* streamCreate(int nStreams);
void streamCreate(cudaStream_t * strms, int nStreams);
void streamDestroy(cudaStream_t *stream,int nStreams);
void createAndStartEvent(cudaEvent_t *startEvent, cudaEvent_t *stopEvent);
float endEvent(cudaEvent_t *startEvent, cudaEvent_t *stopEvent);

