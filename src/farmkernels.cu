#include <iostream>
#include <math.h>
#include <stdlib.h>
 
#include <cstdlib>
#include <algorithm>
#include <ctime>
#include <vector>
#include <future>
#include <iterator>
#include <cosFutStr.h>

#define HIGH 500.0f
#define LOW -500.0f


void randomArray(float *x, int n){
    #ifndef MEASURES
            std::cout<<std::endl<< "X ARRAY: "<<std::endl;  
    #endif
    for(int i=0; i<n;i+=1){
        x[i] = LOW + (float) std::rand() * (HIGH-LOW) / RAND_MAX;   
        #ifndef MEASURES
            std::cout<< x[i] << ", ";  
        #endif
    }
}

/*********
**KERNELS*
**********/
__global__ void emptyKernel(){ return; }

__global__ void cosKernel(int M, int N, float *x_d, int *myclocks, int offset){    
    int idx = offset+blockIdx.x*blockDim.x + threadIdx.x; 
   
    clock_t start =clock();

    for(int j=0;j<M;j+=1)
        x_d[idx]=cosf(x_d[idx]);  

    clock_t end=clock();

    if (threadIdx.x == 0) myclocks[blockIdx.x+(offset/blockDim.x)]=(int)(end-start);
    return ;
}

__global__ void cosGridStride(int M, int N, float *x_d, int *myclocks, int offset){    
    int index = offset+blockIdx.x * blockDim.x + threadIdx.x;
    int stride = blockDim.x * gridDim.x;

    clock_t start =clock();
    for (int i = index; i < N; i += stride)
    {
        for(int j=0;j<M;j+=1)
            x_d[i]=cosf(x_d[i]);  
    }
    clock_t end=clock();

    if (threadIdx.x == 0) myclocks[blockIdx.x+(offset/blockDim.x)]=(int)(end-start);

    return ;
}


/******************
* KERNEL LAUNCERS *
*******************/
float emptyKer(){
    float ms=0;
    cudaEvent_t startEvent, stopEvent;
    checkCuda( cudaEventCreate(&startEvent) );
    checkCuda( cudaEventCreate(&stopEvent) );   

    checkCuda( cudaEventRecord(startEvent,0) );
    
    emptyKernel<<<GRID, BLOCK>>>();

    checkCuda( cudaEventRecord(stopEvent, 0) );
    checkCuda( cudaEventSynchronize(stopEvent) );
    checkCuda( cudaEventElapsedTime(&ms, startEvent, stopEvent) );

    return ms;    
}



/*void cosKer(my_struct *_xs, float *x_d, int *clocks_d, int chunkBytes,
            cudaEvent_t start, cudaEvent_t stop, cudaStream_t strm)
{    
    checkCuda( cudaEventRecord(start,0) );

    checkCuda(cudaMemcpyAsync(x_d, _xs->x_vect, chunkBytes, cudaMemcpyHostToDevice, strm));
    #ifdef LOWPAR
        //cosGridStride<<<GRID, BLOCK, 0, strm>>>(M_iter, N_size, x_d, clocks_d, 0);
        cosGridStride<<<GRID, BLOCK, 0, strm>>>(M_iter, chunk, x_d, clocks_d, 0);
    #else
        //cosKernel<<<GRID, BLOCK, 0, strm>>>(M_iter, N_size, x_d, clocks_d, 0);
        cosKernel<<<GRID, BLOCK, 0, strm>>>(M_iter, chunk, x_d, clocks_d, 0);
    #endif
    checkCuda(cudaMemcpyAsync( _xs->x_vect, x_d, chunkBytes, cudaMemcpyDeviceToHost, strm));
    checkCuda(cudaMemcpyAsync( _xs->clocks, clocks_d, GRID*sizeof(int), cudaMemcpyDeviceToHost, strm));

    checkCuda( cudaEventRecord(stop, 0) );
    checkCuda( cudaEventSynchronize(stop) );
    checkCuda( cudaEventElapsedTime(&_xs->eventTime, start, stop) );            
}*/



void cosKer(std::vector<my_struct> &getDatas, int chunk, int bytesSize )
{
    std::vector<std::future<my_struct>> futures;
    int *clocks_d;
    float *x_d;    
    //float *x = new float[N_size];

    cudaEvent_t startEvent, stopEvent;
    checkCuda( cudaEventCreate(&startEvent) );
    checkCuda( cudaEventCreate(&stopEvent) );    

    checkCuda(cudaMalloc((void **)&x_d, bytesSize)); 
    checkCuda(cudaMalloc((void **)&clocks_d, GRID*sizeof(int)));

    for(int i = 0; i < K_exec; ++i) {
        futures.push_back (std::async(std::launch::deferred,
            [&]() { 
                my_struct _xs;
                _xs.clocks=new int[GRID];
                _xs.x_vect=new float[chunk];
                //randomArray(_xs.x_vect, chunk);
                randomArray(&x[i*chunk], chunk);

                checkCuda( cudaEventRecord(startEvent,0) );

                //checkCuda(cudaMemcpy(x_d, _xs.x_vect, bytesSize, cudaMemcpyHostToDevice)); 
                checkCuda(cudaMemcpy(x_d, &x[i*chunk], bytesSize, cudaMemcpyHostToDevice)); 

                #ifdef LOWPAR
                    cosGridStride<<<GRID, BLOCK>>>(M_iter, chunk, x_d, clocks_d, 0);
                #else
                    cosKernel<<<GRID, BLOCK>>>(M_iter, chunk, x_d,clocks_d, 0);
                #endif
                              
                checkCuda(cudaMemcpy( _xs.x_vect, x_d, bytesSize, cudaMemcpyDeviceToHost));
                checkCuda(cudaMemcpy(_xs.clocks, clocks_d, GRID*sizeof(int), cudaMemcpyDeviceToHost));

                checkCuda( cudaEventRecord(stopEvent, 0) );
                checkCuda( cudaEventSynchronize(stopEvent) );
                checkCuda( cudaEventElapsedTime(&_xs.eventTime, startEvent, stopEvent) );

                return _xs;
            }));          
    }
    for(auto &e : futures) 
        getDatas.push_back(e.get());
}

void cosKerStream(
    int m, int chunk,
    float *x, int *clocks, 
    int offset, cudaStream_t strm)
{
       /* #ifdef LOWPAR
            cosGridStride<<<GRID, BLOCK, offset, strm>>>(m, n, x, clocks, offset);
        #else
            cosKernel<<<GRID, BLOCK, offset, strm>>>(m, n, x, clocks, offset);
        #endif*/
        #ifdef LOWPAR
            cosGridStride<<<GRID, BLOCK, offset, strm>>>(m, chunk, x, clocks, offset);
        #else
            cosKernel<<<GRID, BLOCK, offset, strm>>>(m, chunk, x, clocks, offset);
        #endif
}

float  cosKerStream(
    cudaEvent_t start, cudaEvent_t stop,
    int m, int chunk,//int n,
    float *x, float *cosx,  int *clocks, 
    int offset, cudaStream_t strm)
{
    float ms;  
    //randomArray(x, n);
    //memcpy(cosx,x,N_size);
    randomArray(x,chunk);
    memcpy(cosx,x,chunk);
    
    checkCuda( cudaEventRecord(start,0) );

    //#ifdef STRIDE
    #ifdef LOWPAR
        //cosGridStride<<<GRID, BLOCK, offset, strm>>>(m, n, cosx, clocks, offset);
        cosGridStride<<<GRID, BLOCK, offset, strm>>>(m, chunk, cosx, clocks, offset);
    #else
        //cosKernel<<<GRID, BLOCK, offset, strm>>>(m, n, cosx, clocks, offset);
        cosKernel<<<GRID, BLOCK, offset, strm>>>(m, chunk, cosx, clocks, offset);
    #endif

    checkCuda( cudaEventRecord(stop, 0) );
    checkCuda( cudaEventSynchronize(stop) );
    checkCuda( cudaEventElapsedTime(&ms, start, stop) );
     
    return ms;
}
