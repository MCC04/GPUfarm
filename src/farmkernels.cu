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
#ifdef EMPTY
__global__ void emptyKernel(){ return; }
#endif

/****  COS KERNEL ****/ 
__global__ void cosKernel(int M, int N, float *x_d, int *myclocks, int offset){    
    int idx = offset+blockIdx.x*blockDim.x + threadIdx.x; 
   
    if(idx<N){
        clock_t start =clock();

        for(int j=0; j<M; ++j)
            x_d[idx]=cosf(x_d[idx]);  

        clock_t end=clock();

      //  if (threadIdx.x == 0) myclocks[blockIdx.x+(offset/blockDim.x)]=(int)(end-start);
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

/**** FUTURE ****/
#ifdef FUTURE
std::vector<std::future<hostData_t>> 
    cosKerFuture(int M, int chunk, hostData_t output, float *x, float *x_d, int *clocks_d, cudaStream_t *strm, int nStreams, int offset)
{
    std::vector<std::future<hostData_t>> futures; 

    for(int i = 0; i < K_exec; ++i) {
        const int k = i%nStreams;
        randomArray(x+i*chunk,chunk);

        const int strOffs = k*chunk;
        float *p_xd = x_d+strOffs;
        float *p_x = x+(i*chunk);
        int *p_clocks= clocks_d+(k*GRID);

        futures.push_back (std::async(std::launch::async,     
            [=] (cudaStream_t strm, int strBytes) {
            //[M, chunk, p_xd, p_clocks, output, offset,i]

            //std::cout <<i<<"- going to memcpy x in H2D..."<<std::endl;        
            cudaMemcpy(p_xd, p_x, strBytes, cudaMemcpyHostToDevice);        
            //std::cout <<i<<"- done memcpy x in H2D!"<<std::endl;

            #ifdef LOWPAR
                //std::cout <<i<<"- kernel launch..."<<std::endl;
                cosGridStride<<<GRID, BLOCK,0,strm>>>(M, chunk, p_xd, p_clocks, offset); 
                //std::cout <<i<<"- kernel end!"<<std::endl;
            #else
                //  std::cout <<i<<"- kernel launch..."<<std::endl;
                cosKernel<<<GRID, BLOCK,0,strm>>>(M, chunk, p_xd, p_clocks, offset); 
                //std::cout <<i<<"- kernel end!"<<std::endl;
            #endif

            //std::cout <<i<<"- going to memcpy x in D2H..."<<std::endl;
            cudaMemcpy(output.x, p_xd, strBytes, cudaMemcpyDeviceToHost) ; 
            cudaMemcpy(output.clocks, p_clocks, GRID*sizeof(int), cudaMemcpyDeviceToHost) ; 
            //std::cout <<i<<"- done memcpy x in D2H!"<<std::endl;

            return output;
        }, strm[k], chunk*sizeof(float) ));       


        /*futures.push_back (std::async(std::launch::async,//std::launch::deferred,//       
            [M, chunk, x_d, clocks_d, output, offset,i] (float * x, cudaStream_t strm, int strBytes) {
            
            //std::cout <<i<<"- going to memcpy x in H2D..."<<std::endl;
            
            
            gpuErrchk( cudaMemcpyAsync(x_d, x, strBytes, cudaMemcpyHostToDevice, strm) ); //gpuErrchk( cudaMemcpy(&x_d[i*chunk], &x[i*chunk], chunk*sizeof(float), cudaMemcpyHostToDevice) );          

            //std::cout <<i<<"- done memcpy x in H2D!"<<std::endl;



            #ifdef LOWPAR
                //std::cout <<i<<"- kernel launch..."<<std::endl;

                cosGridStride<<<GRID, BLOCK,0,strm>>>(M, chunk, x_d, clocks_d, offset); //cosGridStride<<<GRID, BLOCK>>>(M_iter, chunk, &x_d[i*chunk], &clocks_d[i*chunk], 0);

                //std::cout <<i<<"- kernel end!"<<std::endl;
            #else

                //  std::cout <<i<<"- kernel launch..."<<std::endl;

                cosKernel<<<GRID, BLOCK,0,strm>>>(M, chunk, x_d, clocks_d, offset); //cosKernel<<<GRID, BLOCK>>>(M_iter, chunk, &x_d[i*chunk],&clocks_d[i*chunk], 0);

                //std::cout <<i<<"- kernel end!"<<std::endl;

            #endif

            //std::cout <<i<<"- going to memcpy x in D2H..."<<std::endl;

            gpuErrchk( cudaMemcpyAsync(output.x, x_d, strBytes, cudaMemcpyDeviceToHost, strm) ); //gpuErrchk( cudaMemcpy( output.x_vect, &x_d[i*chunk], chunk*sizeof(float), cudaMemcpyDeviceToHost) );
            gpuErrchk( cudaMemcpyAsync(output.clocks, clocks_d, GRID*sizeof(int), cudaMemcpyDeviceToHost, strm) ); //gpuErrchk( cudaMemcpy(output.clocks, &clocks_d[i*GRID], GRID*sizeof(int), cudaMemcpyDeviceToHost) );

            cudaStreamSynchronize(strm);
            //std::cout <<i<<"- done memcpy x in D2H!"<<std::endl;

            return output;
        }, x+(i*chunk), strm[k], chunk*sizeof(float) ));*/  
    }
    return futures;
}
#endif





void optimalCosKer( int m, int chunk, float *x, float *cosx, float *x_d, int *clocks, int *clocks_d, cudaStream_t strm, int strBytes, int offset){
    int blockSize;   // The launch configurator returned block size 
    int minGridSize; // The minimum grid size needed to achieve the 
                    // maximum occupancy for a full device launch 
    int gridSize;    // The actual grid size needed, based on input size 

    cudaOccupancyMaxPotentialBlockSize( &minGridSize, &blockSize, cosKernel, 0, 0); 
    // Round up according to array size 
    gridSize = (chunk + blockSize - 1) / blockSize; 

    gpuErrchk( cudaMemcpyAsync(x_d, x, strBytes, cudaMemcpyHostToDevice, strm) ); 

    cosKernel<<< gridSize, blockSize,offset,strm >>>(m, chunk, x_d, clocks_d, offset);

    gpuErrchk( cudaMemcpyAsync( cosx, x_d, strBytes, cudaMemcpyDeviceToHost, strm) );
    gpuErrchk( cudaMemcpyAsync( clocks, clocks_d, GRID*sizeof(int), cudaMemcpyDeviceToHost, strm) );

    //cudaDeviceSynchronize(); 

    // calculate theoretical occupancy
    int maxActiveBlocks;
    cudaOccupancyMaxActiveBlocksPerMultiprocessor( &maxActiveBlocks, cosKernel, blockSize, 0);

    int device;
    cudaDeviceProp props;
    cudaGetDevice(&device);
    cudaGetDeviceProperties(&props, device);
#ifndef MEASURES
    float occupancy = (maxActiveBlocks * blockSize / props.warpSize) / 
                    (float)(props.maxThreadsPerMultiProcessor / 
                            props.warpSize);

    std::cout << "Launched blockSize: " << blockSize<< std::endl
              << "Min Grid Size: " << minGridSize << std::endl
              << "Launched Grid Size: " << gridSize << std::endl
              << "Max active blocks: " << maxActiveBlocks<< std::endl
              << "Theoretical occupancy:" << occupancy << std::endl;
              
  #endif



}


float optimalCosKer( int m, int n, float *x, float *cosx, float *x_d, int *clocks, int *clocks_d){
    int blockSize;   // The launch configurator returned block size 
    int minGridSize; // The minimum grid size needed to achieve the 
                    // maximum occupancy for a full device launch 
    int gridSize;    // The actual grid size needed, based on input size 
    cudaEvent_t startEvent, stopEvent;

    cudaOccupancyMaxPotentialBlockSize( &minGridSize, &blockSize, cosKernel, 0, 0); 
    // Round up according to array size 
    gridSize = (n + blockSize - 1) / blockSize; 

    createAndStartEvent(&startEvent, &stopEvent);   
    gpuErrchk( cudaMemcpy(x_d, x, n*sizeof(float), cudaMemcpyHostToDevice) ); 

    cosKernel<<<gridSize, blockSize>>>(m, n, x_d, clocks_d, 0);

    gpuErrchk( cudaMemcpy( cosx, x_d, n*sizeof(float), cudaMemcpyDeviceToHost) );
    gpuErrchk( cudaMemcpy( clocks, clocks_d, GRID*sizeof(int), cudaMemcpyDeviceToHost) );

        gpuErrchk( cudaPeekAtLastError() );

cudaDeviceSynchronize();

    float ms = endEvent(&startEvent, &stopEvent);
    // calculate theoretical occupancy
    int maxActiveBlocks;
    cudaOccupancyMaxActiveBlocksPerMultiprocessor( &maxActiveBlocks, cosKernel, blockSize, 0);

    int device;
    cudaDeviceProp props;
    cudaGetDevice(&device);
    cudaGetDeviceProperties(&props, device);
#ifndef MEASURES
    float occupancy = (maxActiveBlocks * blockSize / props.warpSize) / 
                    (float)(props.maxThreadsPerMultiProcessor / 
                            props.warpSize);

    std::cout << "Launched blockSize: " << blockSize<< std::endl
              << "Min Grid Size: " << minGridSize << std::endl
              << "Launched Grid Size: " << gridSize << std::endl
              << "Max active blocks: " << maxActiveBlocks<< std::endl
              << "Theoretical occupancy:" << occupancy << std::endl;
   #endif           
  
return ms;


}

/**** STREAM ****/
#ifdef STREAM
void cosKerStream(int m, int chunk, float *x, float *cosx, float *x_d, int *clocks, int *clocks_d, cudaStream_t strm, int strBytes, int offset)
{    
 
    gpuErrchk( cudaMemcpyAsync(x_d, x, strBytes, cudaMemcpyHostToDevice, strm) ); 
    /* #ifdef LOWPAR
        cosGridStride<<<GRID, BLOCK, offset, strm>>>(m, chunk, x_d, clocks_d, offset);
    #else*/
        cosKernel<<<GRID, BLOCK, offset, strm>>>(m, chunk, x_d, clocks_d, offset);
    //#endif   

    #ifndef MEASURES
        gpuErrchk( cudaPeekAtLastError() );
        gpuErrchk( cudaDeviceSynchronize() );
    #endif   
    gpuErrchk( cudaMemcpyAsync( cosx, x_d, strBytes, cudaMemcpyDeviceToHost, strm) );
    gpuErrchk( cudaMemcpyAsync( clocks, clocks_d, GRID*sizeof(int), cudaMemcpyDeviceToHost, strm) );

   /* #ifndef MEASURES
        printClocks(clocks,GRID);
    #endif  */ 
    //cudaStreamSynchronize(strm);       
}


void cosKer(int m, int chunk, float *x, float *cosx, float *x_d, int *clocks, int *clocks_d)
{   
    int xBytes = chunk*sizeof(float);
    int clockBytes = GRID*sizeof(int);
    
    gpuErrchk( cudaMemcpy(x_d, x, xBytes, cudaMemcpyHostToDevice) ); 
    #ifdef LOWPAR
        cosGridStride<<<GRID, BLOCK>>>(m, chunk, x_d, clocks_d, 0);
    #else
        cosKernel<<<GRID, BLOCK>>>(m, chunk, x_d, clocks_d, 0);
    #endif   

    #ifndef MEASURES
        gpuErrchk( cudaPeekAtLastError() );
        gpuErrchk( cudaDeviceSynchronize() );
    #endif   
    gpuErrchk( cudaMemcpy( cosx, x_d, xBytes, cudaMemcpyDeviceToHost) );
    gpuErrchk( cudaMemcpy( clocks, clocks_d, clockBytes, cudaMemcpyDeviceToHost) );

   /* #ifndef MEASURES
        printClocks(clocks,GRID);
    #endif  */ 
    //cudaStreamSynchronize(strm);       
}

#endif


/**** STREAM MANAGED ****/
#ifdef MANAGED
void  cosKerStream(int m, int chunk,//int n,
    float *x, float *cosx,  int *clocks, int offset, cudaStream_t strm)
{
    randomArray(x,chunk);
    memcpy(cosx,x,chunk);

    #ifdef LOWPAR
        cosGridStride<<<GRID, BLOCK, offset, strm>>>(m, chunk, cosx, clocks, offset);
    #else
        cosKernel<<<GRID, BLOCK, offset, strm>>>(m, chunk, cosx, clocks, offset);
    #endif

    cudaStreamSynchronize(strm);
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