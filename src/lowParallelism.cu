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
#include <numeric>

#define HIGH 500.0f
#define LOW -500.0f

#define GRID 1
#define BLOCK 32

//M = iterations; N = size
__global__ void cosKernel(int M, int N, float *x_d, int offset, int *myclocks){    
    int idx = offset+blockIdx.x*blockDim.x + threadIdx.x; 
   
    clock_t start =clock();

    
    for(int i=0;i<N;i+=1){
        for(int j=0;j<M;j+=1)
        {
            x_d[idx+i]=cosf(x_d[idx+i]);  
        }    //x_d[idx]=cosf(x_d[idx]);    
        //

    }
    
    clock_t end=clock();

    if (threadIdx.x == 0) myclocks[blockIdx.x]=(int)(end-start);
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

    
    int gpu_clk=1;
    float msSum=0.0; // elapsed time in milliseconds

    int devId = atoi(argv[1]);
    int K_exec = atoi(argv[2]);
    int M_iter = atoi(argv[3]);
    int N_size = atoi(argv[4]);

    //int BLOCK=N_size;

    float *x=new float[N_size];      
     
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


#ifdef CPU
    std::cout<<std::endl<<"##########################" <<std::endl;
    std::cout<<"########## CPU ##########" <<std::endl;
    std::cout<<"##########################" <<std::endl;
    
    float *cosx=new float[N_size];
    
    for(int i=0; i<N_size;i+=1)
        x[i] = LOW + (float) std::rand() * (HIGH-LOW) / RAND_MAX;   
    
    std::chrono::system_clock::time_point start,end;
    std::vector<double> timeVect;
    for (int r = 0; r < K_exec; ++r) { 

        start=std::chrono::system_clock::now();
        for(int i=0;i<N_size;i+=1)    
            for(int j=0;j<M_iter;j+=1)
                cosx[i]=cos(x[i]);  
                
        end=std::chrono::system_clock::now();

        msSum+=(end-start).count()*1000;
        timeVect.push_back((end - start).count()*1000);
        #if !defined(MEASURES)
            std::cout << std::endl;
            std::cout<< std::endl << "********** ITERATION "<<r<<" **********"<< std::endl;  
            std::cout<<"COSX array : " <<std::endl;  
            for(int j=0; j<N_size;j+=1) 
                std::cout << cosx[j] << ", ";    
            
            std::cout<<std::endl<< "Elapsed time: "<<timeVect[r]<<"ms"<< std::endl;
        #else
            std::cout <<"*"<<r<<"  "<<timeVect[r]; 
        #endif
            
    }
    auto m = std::minmax_element(timeVect.begin(), timeVect.end());
    auto min = m.first;
    auto max = m.second;
    float avg=std::accumulate( timeVect.begin(), timeVect.end(), 0.0)/timeVect.size(); 

    std::cout<<std::endl<<"----"<< *min<<","<<*max<<","<<avg<<std::endl; 

#elif ONE_SM
    std::cout<<std::endl<<"##########################" <<std::endl;
    std::cout<<"########## ONE SM ##########" <<std::endl;
    std::cout<<"##########################" <<std::endl;

    const int bytesSize = N_size*sizeof(float);   
    int* myClock, *myClock_d;     
    float *x_d,*cosx,ms=0.0;
    cosx=new float[N_size];
    myClock=new int[GRID];

    float  rb_wb=0.0;
    //GRID=1;    

    cudaEvent_t startEvent, stopEvent;
    checkCuda( cudaEventCreate(&startEvent) );
    checkCuda( cudaEventCreate(&stopEvent) );

    cudaMalloc(&x_d, bytesSize);
    cudaMalloc(&myClock_d, GRID*sizeof(int));

    memset(x, 0, bytesSize);
    memset(cosx, 0, bytesSize);
    //memset(myClock_d, 0, GRID*sizeof(int));
      
    for(int i=0; i<N_size;i+=1)
        x[i] = LOW + (float) std::rand() * (HIGH-LOW) / RAND_MAX;   
 
       // checkCuda( cudaEventCreate(&startEvent) );
    //checkCuda( cudaEventCreate(&stopEvent) );
    //cudaEventCreate(&startEvent);
    //cudaEventCreate(&stopEvent);
    for (int r = 0; r < K_exec; ++r) {       
        float tmp=0.0;
        checkCuda( cudaEventRecord(startEvent,0) );

        checkCuda(cudaMemcpy(x_d, x, bytesSize, cudaMemcpyHostToDevice));    

        cosKernel<<<GRID, BLOCK>>>(M_iter, N_size, x_d, 0, myClock_d);

        checkCuda(cudaMemcpy( cosx, x_d, bytesSize, cudaMemcpyDeviceToHost));

        checkCuda(cudaMemcpy( myClock, myClock_d, GRID*sizeof(int), cudaMemcpyDeviceToHost));

        checkCuda( cudaEventRecord(stopEvent, 0) );
        checkCuda( cudaEventSynchronize(stopEvent) );
        checkCuda( cudaEventElapsedTime(&tmp, startEvent, stopEvent) );
        //ms+=tmp;      
        
        #if !defined(MEASURES)
            std::cout<<"COSX array : " <<std::endl;  
            for(int j=0; j<N_size;j+=1) 
                std::cout << cosx[j] << ", ";    
            std::cout << std::endl;
            std::cout<< std::endl << "********** ITERATION "<<r<<" **********"<< std::endl;     
        #endif
        rb_wb=bytesSize*2 + GRID*sizeof(int);        

        #ifdef MEASURES
            std::cout <<"*"<<r<<"," <<myClock[0]/(float)gpu_clk << ","<< myClock[0] << ","<< 
                    tmp<< ","<< (rb_wb/tmp/1e6)<<std::endl; 
        #else
            std::cout<< std::endl <<"-------------------------"<< std::endl; 
            std::cout << "GPU freq (kHz) \t Clk (ms) \t my clk \t event time(ms) "<< std::endl;   
            std::cout << gpu_clk << " \t " << myClock[0]/(float)gpu_clk << " \t "<< myClock[0] <<" \t "<< tmp<<std::endl; 
            std::cout<<std::endl<<"----Effective Bandwidth: "<< (rb_wb/tmp/1e6)<<"GB/s"<<std::endl;        
        #endif
        msSum+=tmp;
    }
    cudaFree(x_d);
#endif

    std::cout<<std::endl<<"----Total Events measures: "<< msSum<<"ms"<<std::endl;


    return 0;
}