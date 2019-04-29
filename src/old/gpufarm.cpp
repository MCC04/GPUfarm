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

#define HIGH 500.0f
#define LOW -500.0f
//#define STREAM: is the same as compile with -DSTREAM flag

struct my_struct {
    float *x_vect;
    int *clocks;
    float eventTime;
};

__global__ void cosGridStride(int M, int N, float *x_d, int offset, int *myclocks){    
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

__global__ void cosKernel(int M, int N, float *x_d, int offset, int *myclocks){    
    int idx = offset+blockIdx.x*blockDim.x + threadIdx.x; 
   
    clock_t start =clock();

    for(int j=0;j<M;j+=1)
        x_d[idx]=cosf(x_d[idx]);  

    clock_t end=clock();

    if (threadIdx.x == 0) myclocks[blockIdx.x+(offset/blockDim.x)]=(int)(end-start);
    return ;
}

// Function to check any CUDA runtime API results
inline cudaError_t checkCuda(cudaError_t result)
{
    #if defined(DEBUG) || defined(_DEBUG)
        if (result != cudaSuccess) {
        std::cout <<  "CUDA Runtime Error: " << cudaGetErrorString(result)<< std::endl;
        assert(result == cudaSuccess);
        }
    #endif
        return result;
}

int main(int argc, char **argv){
    std::srand(static_cast <unsigned> (time(NULL)));

    int BLOCK=32;
    int gpu_clk=1;
    float clockSum=0.0, clockAvg=0.0;
    float msSum=0.0, rb_wb=0.0; // elapsed time in milliseconds

    int devId = atoi(argv[1]);
    int K_exec = atoi(argv[2]);
    int M_iter = atoi(argv[3]);
    int N_size = atoi(argv[4]);

    int GRID=0;

    const int bytesSize = N_size*sizeof(float);   

    float *x=new float [N_size];      
     
    checkCuda(cudaDeviceGetAttribute(&gpu_clk, cudaDevAttrClockRate, devId));
    cudaDeviceProp prop;
    checkCuda( cudaSetDevice(devId) );
    checkCuda( cudaGetDeviceProperties(&prop, devId));
    std::cout<<"Device : "<< prop.name <<std::endl;
    std::cout<<"multiproc num : "<< prop.multiProcessorCount <<std::endl;
    std::cout<<"warp size : "<< prop.warpSize <<std::endl;
    std::cout<<"GPU freq (kHz) : "<< gpu_clk <<std::endl<<std::endl;
    
    std::cout << "Items number \t Host iterations \t Kernel iterations " << std::endl;
    std::cout << N_size<<" \t \t \t " << K_exec<< " \t \t \t " << M_iter << std::endl;

#ifdef FUTURE
    std::cout<<std::endl<<"##########################" <<std::endl;
    std::cout<<"##########FUTURE##########" <<std::endl;
    std::cout<<"##########################" <<std::endl;

    int *clocks_d;
    float *x_d;
    std::vector<std::future<my_struct>> futures;
    std::vector<my_struct> getDatas;
    GRID=N_size/BLOCK;    

    cudaEvent_t startEvent, stopEvent;
    checkCuda( cudaEventCreate(&startEvent) );
    checkCuda( cudaEventCreate(&stopEvent) );    

    checkCuda(cudaMalloc(&x_d, bytesSize)); 
    checkCuda(cudaMalloc(&clocks_d, GRID*sizeof(int)));

    for(int i=0; i<N_size;i+=1){
        x[i] = LOW + (float) std::rand() * (HIGH-LOW) / RAND_MAX;   
    }

    for(int i = 0; i < K_exec; ++i) {
        futures.push_back (std::async(std::launch::deferred,
            [&]() { 
                my_struct _xs;
                _xs.clocks=new int[GRID];
                _xs.x_vect=new float[N_size];

                checkCuda( cudaEventRecord(startEvent,0) );

                checkCuda(cudaMemcpy(x_d, x, bytesSize, cudaMemcpyHostToDevice)); 

                #ifdef STRIDE
                    cosGridStride<<<GRID, BLOCK>>>(M_iter, N_size, x_d, 0, clocks_d);
                #else
                    cosKernel<<<GRID, BLOCK>>>(M_iter, N_size, x_d, 0,clocks_d);
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

    int count=0;
    for(auto item : getDatas){  
      
        #if !defined(MEASURES)
            std::cout<< std::endl << "********** ITERATION "<<count<<" **********"<< std::endl;     
            std::cout<< std::endl << "####### COSX vector: "<< std::endl;
            for(int j=0; j<N_size;j+=1) 
                std::cout << item.x_vect[j] << ", ";
            
            std::cout<< std::endl<< "Clock measures"<< std::endl;
        #endif

        clockSum=0;
        int max=item.clocks[0],min=item.clocks[0];

        for(int j=0; j<GRID;j+=1) {
            #if !defined(MEASURES)
                std::cout<< item.clocks[j] << ", ";
            #endif
            clockSum+=item.clocks[j];
            if(item.clocks[j]<min) min=item.clocks[j];
            if(item.clocks[j]>max) max=item.clocks[j];
        }
        clockAvg=clockSum/GRID; 
        rb_wb=bytesSize*2 + GRID*sizeof(float);        
    
        #ifdef MEASURES
            std::cout <<"*"<<count<<"," <<clockAvg/(float)gpu_clk << 
                ","<< min << "," << max << ","<< item.eventTime<< ","<< (rb_wb/item.eventTime/1e6)<<std::endl; 
        #else
            std::cout<< std::endl<<"-------------------------"<< std::endl; 
            std::cout<< "Avg clk (ms) \t \t min clk \t max clk \t event time (ms) "<< std::endl;   
            std::cout << clockAvg/(float)gpu_clk << " \t "<< min << " \t " << max << " \t "<< item.eventTime <<std::endl; 
            std::cout<<std::endl<<"----Effective Bandwidth: "<< (rb_wb/item.eventTime/1e6)<<"GB/s"<<std::endl;
        #endif
        count+=1;
        msSum+=item.eventTime;
    } 

#elif STREAMNEW
    std::cout<<std::endl<<"##########################" <<std::endl;
    std::cout<<"##########STREAM NEW##########" <<std::endl;
    std::cout<<"##########################" <<std::endl;
    int *clocks_d,*clocks;
    
    float *x_d,*cosx,ms=0.0;
    cosx=new float[N_size];
    const int streamSize = N_size;
    const int streamBytes = streamSize* sizeof(float) ;
    GRID=streamSize/BLOCK;    
    clocks=new int[GRID]; 

    cudaEvent_t startEvent, stopEvent;
    checkCuda( cudaEventCreate(&startEvent) );
    checkCuda( cudaEventCreate(&stopEvent) );

    #if !defined(MEASURES)
        std::cout << "Stream Size \t Stream bytes \t GRID \t BLOCK " << std::endl;
        std::cout << streamSize<<" \t \t " <<streamBytes<< " \t \t " << GRID <<" \t " << BLOCK << std::endl;
    #endif
    cudaMalloc(&x_d, bytesSize);
    cudaMalloc(&clocks_d,GRID*sizeof(int));

    cudaStream_t stream[K_exec];
    for (int i = 0; i < K_exec; ++i)
        checkCuda(cudaStreamCreate(&stream[i]));

    memset(x, 0, bytesSize);
    memset(cosx, 0, bytesSize);
    memset(clocks, 0, GRID*sizeof(int));
       
    //random generation of X vector
    for(int i=0; i<N_size;i+=1){
        x[i] = LOW + (float) std::rand() * (HIGH-LOW) / RAND_MAX;   
    }

    for (int r = 0; r < K_exec; ++r) {  
        ms=0;     

        checkCuda( cudaEventRecord(startEvent,0) );
        cudaMemcpyAsync(x_d, x, streamBytes, cudaMemcpyHostToDevice, stream[r]);    

        #ifdef STRIDE
            cosGridStride<<<GRID, BLOCK, 0, stream[r]>>>(M_iter, N_size, x_d, 0, clocks_d);
        #else
            cosKernel<<<GRID, BLOCK, 0, stream[r]>>>(M_iter, N_size, x_d, 0, clocks_d);
        #endif
        cudaMemcpyAsync( cosx, x_d, streamBytes, cudaMemcpyDeviceToHost, stream[r]);
        cudaMemcpyAsync( clocks, clocks_d, GRID*sizeof(int), cudaMemcpyDeviceToHost, stream[r]);

        checkCuda( cudaEventRecord(stopEvent, 0) );
        checkCuda( cudaEventSynchronize(stopEvent) );
        checkCuda( cudaEventElapsedTime(&ms, startEvent, stopEvent) );
     
        #if !defined(MEASURES)
            std::cout<<"COSX array : " <<std::endl;  
            for(int j=0; j<N_size;j+=1) 
                std::cout << cosx[j] << ", ";    
            std::cout << std::endl;
            std::cout<< std::endl << "********** ITERATION "<<r<<" **********"<< std::endl;     
            std::cout <<"Clocks measures"<< std::endl;
        #endif    
        int max=clocks[0],min=clocks[0];
        clockSum=0;
        for(int j=0; j<GRID;j+=1) {
            #if !defined(MEASURES)
                std::cout << clocks[j] << ", ";
            #endif
            clockSum+=clocks[j];
            if(clocks[j]<min) min=clocks[j];
            if(clocks[j]>max) max=clocks[j];
        }
        clockAvg=clockSum/GRID;
        rb_wb=bytesSize*2 + GRID*sizeof(float);        

        #ifdef MEASURES
            std::cout <<"*"<<r<<","<<clockAvg/(float)gpu_clk << ","<< min << "," << max << ","<< 
                    ms<< ","<< (rb_wb/ms/1e6)<<std::endl; 
        #else
            std::cout<< std::endl <<"-------------------------"<< std::endl; 
            std::cout << "GPU freq (kHz) \t Avg clk (ms) \t min clk \t max clk \t event time(ms) "<< std::endl;   
            std::cout << gpu_clk << " \t " << clockAvg/(float)gpu_clk << " \t "<< min << " \t " << max <<" \t "<< ms<<std::endl; 
            std::cout<<std::endl<<"----Effective Bandwidth: "<< (rb_wb/ms/1e6)<<"GB/s"<<std::endl;        
        #endif
        msSum+=ms;
    }
    for (int i = 0; i < K_exec; ++i)
        checkCuda(cudaStreamDestroy(stream[i]));


#elif MANAGEDNEW
        std::cout<<std::endl<<"##################################" <<std::endl;
        std::cout<<"##########STREAM MANAGED NEW##########" <<std::endl;
        std::cout<<"##################################" <<std::endl;
        const int streamSize = N_size ;
        const int streamBytes = streamSize* sizeof(float) ;
    
        float ms=0.0;
        GRID=streamSize/BLOCK;
        int *clocks;
        clocks=new int[GRID]; 
    
        cudaEvent_t startEvent, stopEvent;
        checkCuda( cudaEventCreate(&startEvent) );
        checkCuda( cudaEventCreate(&stopEvent) );
    
        #if !defined(MEASURES)
            std::cout << "Stream Size \t Stream bytes \t GRID \t BLOCK " << std::endl;
            std::cout << streamSize<<" \t \t " <<streamBytes<< " \t \t " << GRID <<" \t " << BLOCK << std::endl;
        #endif
    
        cudaStream_t stream[K_exec];
        for (int i = 0; i < K_exec; ++i)
            checkCuda(cudaStreamCreate(&stream[i]));
    
        cudaMallocManaged(&x, bytesSize);
        cudaMallocManaged(&clocks, GRID*sizeof(int));
    
        memset(x, 0, bytesSize);
        memset(clocks, 0, GRID*sizeof(int));
      
        for(int i=0; i<N_size;i+=1){
            x[i] = LOW + (float) std::rand() * (HIGH-LOW) / RAND_MAX;   
        }
    
        for (int r = 0; r < K_exec; ++r) {   
            ms=0;          
    
            checkCuda( cudaEventRecord(startEvent,0) ); 
            
            cosKernel<<<GRID, BLOCK, 0, stream[r]>>>(M_iter, N_size, x, 0, clocks);

            checkCuda( cudaEventRecord(stopEvent, 0) );
            checkCuda( cudaEventSynchronize(stopEvent) );
            checkCuda( cudaEventElapsedTime(&ms, startEvent, stopEvent) );
            
    
            #if !defined(MEASURES)
                std::cout<< std::endl << "********** ITERATION "<<r<<" **********"<< std::endl;     
                std::cout<<"COSX array : " <<std::endl;  
                for(int j=0; j<N_size;j+=1) {
                    std::cout << x[j] << ", ";
                }
                std::cout<< std::endl <<"Clocks measures"<< std::endl;  
            #endif
            
            int max=clocks[0],min=clocks[0];   
            clockSum=0; 
            for(int j=0; j<GRID;j+=1) {
                #if !defined(MEASURES)
                    std::cout << clocks[j] << ", ";
                #endif
                clockSum+=clocks[j];
                if(clocks[j]<min) min=clocks[j];
                if(clocks[j]>max) max=clocks[j];
            }
            clockAvg=clockSum/GRID; 
            rb_wb=bytesSize*2 + GRID*sizeof(float);
    
            #ifdef MEASURES
                std::cout <<"*"<<r<<","<< clockAvg/(float)gpu_clk << ","<< min << "," << max << ","<< 
                    ms<< ","<< (rb_wb/ms/1e6)<<std::endl; 
            #else
                std::cout<< std::endl <<"-------------------------"<< std::endl; 
                std::cout << "Avg clk (ms) \t min clk \t max clk \t event time (ms)"<< std::endl;   
                std::cout << clockAvg/(float)gpu_clk << " \t "<< min << " \t " << max <<" \t "<< ms  <<std::endl;   
                std::cout<<std::endl<<"----Effective Bandwidth: "<< (rb_wb/ms/1e6)<<"GB/s"<<std::endl;
            #endif    
            msSum+=ms;
        }
        for (int i = 0; i < K_exec; ++i)
            checkCuda(cudaStreamDestroy(stream[i]));

    std::cout<<std::endl<<"----Total Events measures: "<< msSum<<"ms"<<std::endl;

    #if defined(FUTURE) || defined(STREAM)
        cudaFree(x_d);
        cudaFree(clocks_d);
    #elif defined(STREAMMANAGED)
        cudaFree(x);
        cudaFree(clocks);
    #endif

    return 0;
}