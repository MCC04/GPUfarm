#include <iostream>
#include <math.h>
#include <stdlib.h>
 
#include <algorithm>
//#include <ctime>
//#include <vector>
//#include <future>
//#include <iterator>
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
/*void futCheck(int i, std::string mess){
    #ifndef MEASURES
        std::cout <<i<<mess<<std::endl;
    #endif  
}*/

/**** FUTURE ****/
#ifdef FUTURE
std::vector<std::future<hostData_t>> 
    cosKerFuture(int M, int chunk, hostData_t output, float *x, float *x_d, int *clocks_d, cudaStream_t *strm, int nStreams, int offset)
{
    std::vector<std::future<hostData_t>> futures; 
    //int strBytes = ;

    for(int i = 0; i < K_exec; ++i) {
        int k = i%nStreams;
        randomArray(x+i*chunk,chunk);
  
     
        futures.push_back (std::async(std::launch::async,//std::launch::deferred,//       
                [M, chunk, output, x_d, clocks_d, offset,i] (float * x, cudaStream_t strm, int strBytes) {
                
                std::cout <<i<<"- going to memcpy x in H2D..."<<std::endl;
              
                gpuErrchk( cudaMemcpyAsync(x_d, x, strBytes, cudaMemcpyHostToDevice, strm) ); //gpuErrchk( cudaMemcpy(&x_d[i*chunk], &x[i*chunk], chunk*sizeof(float), cudaMemcpyHostToDevice) );          

                std::cout <<i<<"- done memcpy x in H2D!"<<std::endl;



                #ifdef LOWPAR
                    std::cout <<i<<"- kernel launch..."<<std::endl;

                    cosGridStride<<<GRID, BLOCK,0,strm>>>(M, chunk, x_d, clocks_d, offset); //cosGridStride<<<GRID, BLOCK>>>(M_iter, chunk, &x_d[i*chunk], &clocks_d[i*chunk], 0);

                    std::cout <<i<<"- kernel end!"<<std::endl;
                #else

                    std::cout <<i<<"- kernel launch..."<<std::endl;

                    cosKernel<<<GRID, BLOCK,0,strm>>>(M, chunk, x_d, clocks_d, offset); //cosKernel<<<GRID, BLOCK>>>(M_iter, chunk, &x_d[i*chunk],&clocks_d[i*chunk], 0);

                    std::cout <<i<<"- kernel end!"<<std::endl;

                #endif



                std::cout <<i<<"- going to memcpy x in D2H..."<<std::endl;

                gpuErrchk( cudaMemcpyAsync(output.x, x_d, strBytes, cudaMemcpyDeviceToHost, strm) ); //gpuErrchk( cudaMemcpy( output.x_vect, &x_d[i*chunk], chunk*sizeof(float), cudaMemcpyDeviceToHost) );
                gpuErrchk( cudaMemcpyAsync(output.clocks, clocks_d, GRID*sizeof(int), cudaMemcpyDeviceToHost, strm) ); //gpuErrchk( cudaMemcpy(output.clocks, &clocks_d[i*GRID], GRID*sizeof(int), cudaMemcpyDeviceToHost) );


                std::cout <<i<<"- done memcpy x in D2H!"<<std::endl;

                return output;
            }, x+(i*chunk), strm[k], chunk*sizeof(float) ));       
    }
    return futures;
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