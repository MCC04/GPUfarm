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
    /*#ifndef MEASURES
            std::cout<<std::endl<< "X ARRAY: "<<std::endl;  
    #endif*/
    for(int i=0; i<n;i+=1){
        x[i] = LOW + (float) std::rand() * (HIGH-LOW) / RAND_MAX;   
       /* #ifndef MEASURES
            std::cout<< x[i] << ", ";  
        #endif*/
    }
}

/*********
**KERNELS*
**********/
#ifdef EMPTY
__global__ void emptyKernel(){ return; }
#endif

/**** GRID-STRIDE COS KERNEL ****/ 
__global__ void cosKernel(int M, int N, float *x_d, int *myclocks, int offset){    
    int idx = offset+blockIdx.x*blockDim.x + threadIdx.x; 
   
    if(idx<N){
        clock_t start =clock();

        for(int j=0; j<M; ++j)
            x_d[idx]=cosf(x_d[idx]);  

        clock_t end=clock();

        if (threadIdx.x == 0) myclocks[blockIdx.x+(offset/blockDim.x)]=(int)(end-start);
    }
    return ;
}


/**** GRID-STRIDE COS KERNEL ****/ 
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

/**** STREAM ****/
#ifdef FUTURE
float cosKer(std::vector<my_struct> &getDatas, int chunk, int bytesSize )
{
    std::vector<std::future<my_struct>> futures;
    int *clocks_d;
    float *x_d; 

    float *x = new float[N_size]; //gpuErrchk( cudaMallocHost((void **)&x, N_size*sizeof(float)) ); //pinned x    
    //float *cosx = new float[N_size]; //gpuErrchk( cudaMallocHost((void **)&cosx, N_size*sizeof(float)) ); //pinned x    
    float *clockss = new float[K_exec*GRID]; //gpuErrchk( cudaMallocHost((void **)&clockss, K_exec*GRID*sizeof(float)) ); //pinned x
  

    gpuErrchk( cudaMalloc((void **)&x_d, N_size*sizeof(float)) ); 
    gpuErrchk( cudaMalloc((void **)&clocks_d, GRID*K_exec*sizeof(int)) );

    cudaEvent_t startEvent, stopEvent;
    createAndStartEvent(startEvent, stopEvent);
    /*gpuErrchk( cudaEventCreate(&startEvent) );
    gpuErrchk( cudaEventCreate(&stopEvent) ); 
    gpuErrchk( cudaEventRecord(startEvent,0) );*/

    randomArray(x, N_size);

    cudaStream_t *stream=streamCreate(3);
    for(int i = 0; i < K_exec; ++i) {
        
     
        futures.push_back (
         std::async(std::launch::async,//std::launch::deferred,//       
             [x,x_d,clocks_d,chunk,stream](int i ) { //[x,x_d,clocks_d,chunk](int i ) { 

                my_struct _xs;
                _xs.clocks=new int[GRID];
                _xs.x_vect=new float[chunk];
                int k = i%3;

                #ifndef MEASURES
                    std::cout <<i<<" - going to memcpy x in H2D..."<<std::endl;
                #endif                
                gpuErrchk( cudaMemcpyAsync(&x_d[i*chunk], &x[i*chunk], chunk*sizeof(float), cudaMemcpyHostToDevice, stream[k]) ); //gpuErrchk( cudaMemcpy(&x_d[i*chunk], &x[i*chunk], chunk*sizeof(float), cudaMemcpyHostToDevice) );          
                #ifndef MEASURES
                    std::cout << i<<"- done memcpy x in H2D!"<<std::endl;
                #endif

                #ifdef LOWPAR
                    #ifndef MEASURES                    
                        std::cout << i<<"- kernel launch..."<<std::endl;
                    #endif
                    cosGridStride<<<GRID, BLOCK,0,stream[k]>>>(M_iter, chunk, &x_d[i*chunk], &clocks_d[i*chunk], 0); //cosGridStride<<<GRID, BLOCK>>>(M_iter, chunk, &x_d[i*chunk], &clocks_d[i*chunk], 0);
                    #ifndef MEASURES 
                        std::cout << i<<"- kernel end!"<<std::endl;
                    #endif
                #else
                   
                 
                    #ifndef MEASURES                    
                        std::cout << i<<"- kernel launch..."<<std::endl;
                    #endif
                    cosKernel<<<GRID, BLOCK,0,stream[k]>>>(M_iter, chunk, &x_d[i*chunk],&clocks_d[i*chunk], 0); //cosKernel<<<GRID, BLOCK>>>(M_iter, chunk, &x_d[i*chunk],&clocks_d[i*chunk], 0);
                    #ifndef MEASURES 
                        std::cout << i<<"- kernel end!"<<std::endl;
                    #endif

                #endif
                              
                #ifndef MEASURES
                    std::cout <<i<<" - going to memcpy x in D2H..."<<std::endl;
                #endif  
                gpuErrchk( cudaMemcpyAsync(_xs.x_vect, &x_d[i*chunk], chunk*sizeof(float), cudaMemcpyDeviceToHost, stream[k]) ); //gpuErrchk( cudaMemcpy( _xs.x_vect, &x_d[i*chunk], chunk*sizeof(float), cudaMemcpyDeviceToHost) );
                gpuErrchk( cudaMemcpyAsync(_xs.clocks, &clocks_d[i*GRID], GRID*sizeof(int), cudaMemcpyDeviceToHost, stream[k]) ); //gpuErrchk( cudaMemcpy(_xs.clocks, &clocks_d[i*GRID], GRID*sizeof(int), cudaMemcpyDeviceToHost) );
                #ifndef MEASURES
                    std::cout << i<<"- done memcpy x in D2H!"<<std::endl;
                #endif
                _xs.eventTime=0;

                return _xs;
            },i));       
    }
    float ms=0.0f;

    
    for(auto &e : futures) 
            getDatas.push_back(e.get()); 
    
    /*gpuErrchk( cudaEventRecord(stopEvent, 0) );
    gpuErrchk( cudaEventSynchronize(stopEvent) );
    gpuErrchk( cudaEventElapsedTime(&ms, startEvent, stopEvent) );*/
    msTot = endEvent(startEvent, stopEvent);

    #ifndef MEASURES
        std::cout << "EVENT TIME FUTURE: "<< ms<<std::endl;
    #endif
    streamDestroy(stream,3);

    cudaFreeHost(x);
    //cudaFreeHost(cosx);
    cudaFreeHost(clockss);
    cudaFree(x_d);
    cudaFree(clocks_d);

    return ms;
}
#endif

/**** STREAM ****/
#ifdef STREAM

void cosKerStream(int m, int chunk, float *x, float *cosx, float *x_d, int *clocks, int *clocks_d, cudaStream_t strm, int strBytes, int offset)
{
    
    gpuErrchk( cudaMemcpyAsync(x_d, x, strBytes, cudaMemcpyHostToDevice, strm) ); 
    #ifdef LOWPAR
        cosGridStride<<<GRID, BLOCK, offset, strm>>>(m, chunk, x_d, clocks_d, offset);
    #else
        cosKernel<<<GRID, BLOCK, offset, strm>>>(m, chunk, x_d, clocks_d, offset);
    #endif   

    #ifndef MEASURES
        gpuErrchk( cudaPeekAtLastError() );
        gpuErrchk( cudaDeviceSynchronize() );
    #endif   
    gpuErrchk( cudaMemcpyAsync( cosx, x_d, strBytes, cudaMemcpyDeviceToHost, strm) );
    gpuErrchk( cudaMemcpyAsync( clocks, clocks_d, GRID*sizeof(int), cudaMemcpyDeviceToHost, strm) );

    #ifndef MEASURES
        printClocks(clocks,GRID);
    #endif      
    
}
#endif


/**** STREAM MANAGED ****/
#ifdef MANAGED
void  cosKerStream(
    //cudaEvent_t start, cudaEvent_t stop,
    int m, int chunk,//int n,
    float *x, float *cosx,  int *clocks, 
    int offset, cudaStream_t strm)
{
    float ms;  
    //randomArray(x, n);
    //memcpy(cosx,x,N_size);
    randomArray(x,chunk);
    memcpy(cosx,x,chunk);
    
    //gpuErrchk( cudaEventRecord(start,0) );

    //#ifdef STRIDE
    #ifdef LOWPAR
        //cosGridStride<<<GRID, BLOCK, offset, strm>>>(m, n, cosx, clocks, offset);
        cosGridStride<<<GRID, BLOCK, offset, strm>>>(m, chunk, cosx, clocks, offset);
    #else
        //cosKernel<<<GRID, BLOCK, offset, strm>>>(m, n, cosx, clocks, offset);
        cosKernel<<<GRID, BLOCK, offset, strm>>>(m, chunk, cosx, clocks, offset);
    #endif

    /*gpuErrchk( cudaEventRecord(stop, 0) );
    gpuErrchk( cudaEventSynchronize(stop) );
    gpuErrchk( cudaEventElapsedTime(&ms, start, stop) );*/
     
   // return ms;
}
#endif


/**** EMPTY ****/
#ifdef EMPTY
float emptyKer(){
    float ms=0;
    cudaEvent_t startEvent, stopEvent;
    gpuErrchk( cudaEventCreate(&startEvent) );
    gpuErrchk( cudaEventCreate(&stopEvent) );   

    gpuErrchk( cudaEventRecord(startEvent,0) );
    
    emptyKernel<<<GRID, BLOCK>>>();

    gpuErrchk( cudaEventRecord(stopEvent, 0) );
    gpuErrchk( cudaEventSynchronize(stopEvent) );
    gpuErrchk( cudaEventElapsedTime(&ms, startEvent, stopEvent) );

    return ms;    
}
#endif