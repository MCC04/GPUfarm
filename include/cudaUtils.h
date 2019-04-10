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

cudaError_t checkCuda(cudaError_t result);
cudaStream_t* streamCreate(int nStreams);
void streamDestroy(cudaStream_t *stream,int nStreams);

