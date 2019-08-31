#include <iostream>
#include <math.h>
#include <stdlib.h> 
#include <algorithm>

#include <cosFutStr.h>

#define HIGH 500.0f
#define LOW -500.0f

void randomArray(float *x, int n){
    for(int i=0; i<n;i+=1){
        x[i] = LOW + (float) std::rand() * (HIGH-LOW) / RAND_MAX;   
    }
}

/*********
**KERNELS*
**********/
/****  COS KERNEL ****/ 
__global__ void cosKernel(int M, int N, float *x_d){    
    int idx = blockIdx.x*blockDim.x + threadIdx.x; 
   
    if(idx<N){
        float x = x_d[idx];
        for(int j=0; j<M; ++j)
            x=cosf(x);  

        x_d[idx] = x;
    }
    return ;
}

/**** GRID-STRIDE COS KERNEL ****/ 
__global__ void cosGridStride(int M, int N, float *x_d){    
    int index = blockIdx.x * blockDim.x + threadIdx.x;
    int stride = blockDim.x * gridDim.x;

    float x;
    for (int i = index; i < N; i += stride)
    {
        x = x_d[i];
        for(int j=0;j<M;j+=1)
            x=cosf(x);  

        x_d[i] = x;
    }
    return ;
}


/******************
* KERNEL LAUNCERS *
*******************/

/**** DATAPAR ****/

#ifdef DATAPAR
float optimalCosKer( int m, int n, float *x, float *cosx, float *x_d){
    int blockSize;   // The launch configurator returned block size 
    int minGridSize; // The minimum grid size needed to achieve the maximum occupancy for a full device launch 
    cudaEvent_t startEvent, stopEvent;

    cudaOccupancyMaxPotentialBlockSize( &minGridSize, &blockSize, cosKernel, 0, 0); 
    
    GRID = (n + blockSize - 1) / blockSize; // Round up according to array size 
    BLOCK=blockSize;
    // Events creation and start
    createAndStartEvent(&startEvent, &stopEvent);  
    // H2D mem copy 
    gpuErrchk( cudaMemcpy(x_d, x, n*sizeof(float), cudaMemcpyHostToDevice) ); 
    // Kernel call
    cosKernel<<<GRID, BLOCK>>>(m, n, x_d);
    // D2H mem copy 
    gpuErrchk( cudaMemcpy( cosx, x_d, n*sizeof(float), cudaMemcpyDeviceToHost) );
    
    float ms = endEvent(&startEvent, &stopEvent);
    
    #ifndef MEASURES
        // Error tracking and event time
        gpuErrchk( cudaPeekAtLastError() );
        // Calculate theoretical occupancy
        int maxActiveBlocks;
        cudaOccupancyMaxActiveBlocksPerMultiprocessor( &maxActiveBlocks, cosKernel, blockSize, 0);

        int device;
        cudaDeviceProp props;
        cudaGetDevice(&device);
        cudaGetDeviceProperties(&props, device);
        
        float occupancy = (maxActiveBlocks * blockSize / props.warpSize) / 
                        (float)(props.maxThreadsPerMultiProcessor / 
                                props.warpSize);

        std::cout << "Launched blockSize: " << BLOCK<< std::endl
                << "Min Grid Size: " << minGridSize << std::endl
                << "Launched Grid Size: " << GRID << std::endl
                << "Max active blocks: " << maxActiveBlocks<< std::endl
                << "Theoretical occupancy:" << occupancy << std::endl;
   #endif           
  
    return ms;
}
#endif

/**** STREAM ****/
#ifdef STREAM
void streamCosine(int m, int chunk, float *x, float *cosx, float *x_d, cudaStream_t strm, int strBytes)
{     
    // H2D mem copy 
    gpuErrchk( cudaMemcpyAsync(x_d, x, strBytes, cudaMemcpyHostToDevice, strm) ); 
    // Kernel call
    cosKernel<<<GRID, BLOCK, 0, strm>>>(m, chunk, x_d); 
    #ifndef MEASURES
        gpuErrchk( cudaPeekAtLastError() );
    #endif   
    // D2H mem copy 
    gpuErrchk( cudaMemcpyAsync( cosx, x_d, strBytes, cudaMemcpyDeviceToHost, strm) );
}


void cosine(int m, int chunk, float *x, float *cosx, float *x_d)
{   
    int xBytes = chunk*sizeof(float);
    // H2D mem copy 
    gpuErrchk( cudaMemcpy(x_d, x, xBytes, cudaMemcpyHostToDevice) ); 
    // Kernel call
    cosKernel<<<GRID, BLOCK>>>(m, chunk, x_d);  
    #ifndef MEASURES
        gpuErrchk( cudaPeekAtLastError() );
    #endif   
    // D2H mem copy 
    gpuErrchk( cudaMemcpy( cosx, x_d, xBytes, cudaMemcpyDeviceToHost) );
}
#endif


/**** FUTURE ****/
#ifdef FUTURE
std::vector<std::future<float *>> 
    streamFutureCosine(int M, int chunk, float *cosx, float *x, float *x_d, cudaStream_t *streams, int nStreams)
{
    std::vector<std::future<float *>> futures; 

    for(int i = 0; i < N_size/chunk; ++i) {
        const int k = i%nStreams;
        randomArray(x+i*chunk,chunk);

        const int strOffs = k*chunk;
        float *p_xd = x_d+strOffs;
        float *p_x = x+(i*chunk);
        float *p_cosx = cosx+(i*chunk);

        futures.push_back (std::async(std::launch::async,     
            [=] (cudaStream_t strm, int strBytes) {
            // H2D mem copy 
            cudaMemcpyAsync(p_xd, p_x, strBytes, cudaMemcpyHostToDevice,strm);        
            // Kernel call
            cosKernel<<<GRID, BLOCK,0,strm>>>(M, chunk, p_xd); 
            // D2H mem copy 
            cudaMemcpyAsync(p_cosx, p_xd, strBytes, cudaMemcpyDeviceToHost,strm) ; 
            #ifndef MEASURES
                gpuErrchk( cudaPeekAtLastError() );
            #endif 

            return p_cosx;
        }, streams[k], chunk*sizeof(float) ));       
    }
    return futures;
}
#endif


/**** STREAM MANAGED ****/
#ifdef MANAGED
void  unifiedStreamCosine(int m, int chunk, float *x, float *cosx, cudaStream_t strm)
{
    randomArray(x,chunk);
    memcpy(cosx,x,chunk);

    #ifdef LOWPAR
        cosGridStride<<<GRID, BLOCK, 0, strm>>>(m, chunk, cosx);
    #else
        cosKernel<<<GRID, BLOCK, 0, strm>>>(m, chunk, cosx);
    #endif

    cudaStreamSynchronize(strm);
}
#endif