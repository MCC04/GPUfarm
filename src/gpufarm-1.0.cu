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

struct my_struct {
    float *x_vect;
    int *clocks;
    float eventTime;
};

//#define STREAM: is the same as compile with -DSTREAM flag

//M = iterations; N = size
__global__ void cosKernel(int M, int N, float *x_d, int offset, int *myclocks){    
    int idx = offset+blockIdx.x*blockDim.x + threadIdx.x; 
    float tmp;

    clock_t start =clock();

    tmp=x_d[idx];
    for(int j=0;j<M;j+=1){
        //tmp=x_d[idx];
        //x_d[idx]=cosf(tmp);
        x_d[idx]=cosf(x_d[idx]);
    }    

    clock_t end=clock();

    if (threadIdx.x == 0) myclocks[blockIdx.x]=(int)(end-start);

    //myclocks[idx]=(int)(end-start);
    return ;
}

// Convenience function for checking CUDA runtime API results
// can be wrapped around any runtime API call. No-op in release builds.
inline
cudaError_t checkCuda(cudaError_t result)
{
    #if defined(DEBUG) || defined(_DEBUG)
        if (result != cudaSuccess) {
        std::cout <<  "CUDA Runtime Error: " << cudaGetErrorString(result)<< std::endl;
        assert(result == cudaSuccess);
        }
    #endif
        return result;
}

void printResults(float *cosx, int *clks){

}

int main(int argc, char **argv){
    std::srand(static_cast <unsigned> (time(NULL)));
    int blockSize=56;
    int gpu_clk=1;
    float clockSum=0.0, clockAvg=0.0;

    //if (argc > 1) devId = atoi(argv[1]);

    int devId = atoi(argv[1]);
    int K_exec = atoi(argv[2]);
    int M_iter = atoi(argv[3]);
    int N_size = atoi(argv[4]);

    const int bytesSize = N_size*sizeof(float);    
    float *x, *x_d, *cosx;
    x=new float [N_size];
    cosx=new float[N_size];  
    
   
    float ms=0.0; // elapsed time in milliseconds
    float msSum=0.0;

    checkCuda(cudaDeviceGetAttribute(&gpu_clk, cudaDevAttrClockRate, devId));

    cudaDeviceProp prop;
    checkCuda( cudaSetDevice(devId) );
    checkCuda( cudaGetDeviceProperties(&prop, devId));
    std::cout<<"Device : "<< prop.name <<std::endl;
    std::cout<<"multiproc num : "<< prop.multiProcessorCount <<std::endl;
    std::cout<<"warp size : "<< prop.warpSize <<std::endl;
    std::cout<<"GPU freq (kHz) : "<< gpu_clk <<std::endl<<std::endl;


    
    //random generation of X vector
    //std::cout<<"X array : " <<std::endl;    
   /* for(int i=0; i<N_size;i+=1){
        x[i] = LOW + (float) std::rand() * (HIGH-LOW) / RAND_MAX;   
        std::cout<< x[i] << ", ";    
    }
    std::cout <<std::endl<<"********************"<<std::endl;  
    */

std::cout << "Items number \t Host iterations \t Kernel iterations " << std::endl;
std::cout << N_size<<" \t \t \t " << K_exec<< " \t \t \t " << M_iter << std::endl;

#ifdef FUTURE
    std::cout<<std::endl<<"##########################" <<std::endl;
    std::cout<<"##########FUTURE##########" <<std::endl;
    std::cout<<"##########################" <<std::endl;

    std::vector<std::future<my_struct>> futures;
    std::vector<my_struct> getDatas;
    int GRID=N_size/blockSize;
    int *clks, *clocks_d;
    //clocks=new int[N_size]; 
    clks=new int[GRID]; 

    cudaEvent_t startEvent, stopEvent;
    checkCuda( cudaEventCreate(&startEvent) );
    checkCuda( cudaEventCreate(&stopEvent) );  
  

    checkCuda(cudaMalloc(&x_d, bytesSize)); 
    checkCuda(cudaMalloc(&clocks_d, GRID*sizeof(int)));

    for(int i=0; i<N_size;i+=1){
        x[i] = LOW + (float) std::rand() * (HIGH-LOW) / RAND_MAX;   
        //std::cout<< x[i] << ", ";    
    }

    for(int i = 0; i < K_exec; ++i) {
        futures.push_back (std::async(std::launch::deferred,
            [&]() { //int M, int N, float *x
                my_struct _xs;

                _xs.clocks=new int[GRID];
                _xs.x_vect=new float[N_size];
                checkCuda( cudaEventRecord(startEvent,0) );
                checkCuda(cudaMemcpy(x_d, x, bytesSize, cudaMemcpyHostToDevice)); 

                cosKernel<<<GRID, blockSize>>>(M_iter, N_size, x_d, 0,clocks_d);
                
                checkCuda(cudaMemcpy( _xs.x_vect, x_d, bytesSize, cudaMemcpyDeviceToHost));
                checkCuda(cudaMemcpy(_xs.clocks, clocks_d, GRID*sizeof(int), cudaMemcpyDeviceToHost));

                checkCuda( cudaEventRecord(stopEvent, 0) );
                checkCuda( cudaEventSynchronize(stopEvent) );
                checkCuda( cudaEventElapsedTime(&_xs.eventTime, startEvent, stopEvent) );
                            
                
                //_xs.x_vect=cosx;
                //_xs.clocks=clks;
                //_xs.eventTime=ms;
                return _xs;
            }));          
    }
    for(auto &e : futures) 
        getDatas.push_back(e.get());

    int count=0;
    for(auto item : getDatas){   
        std::cout<< std::endl << "********** ITERATION "<<count<<" **********"<< std::endl;     
        std::cout<< std::endl << "####### COSX vector: "<< std::endl;
        for(int j=0; j<N_size;j+=1) {
            std::cout << item.x_vect[j] << ", ";
        }
        std::cout<< "Clock measures"<< std::endl;
        clockSum=0;

        int max=item.clocks[0],min=item.clocks[0];
        for(int j=0; j<GRID;j+=1) {
            std::cout<< item.clocks[j] << ", ";
            clockSum+=item.clocks[j];
            if(item.clocks[j]<min) min=item.clocks[j];
            if(item.clocks[j]>max) max=item.clocks[j];
        }
        clockAvg=clockSum/GRID; 
        //auto minmax = std::minmax_element(std::begin(item.clocks), std::end(item.clocks));
        std::cout<< std::endl<<"-------------------------"<< std::endl; 
        std::cout<< "Avg clk (ms) \t min clk \t max clk \t event time (ms) "<< std::endl;   
        std::cout << clockAvg/(float)gpu_clk << " \t "<< min << " \t \t " << max << " \t \t "<< item.eventTime <<std::endl; 
       // std::cout<< std::endl "GPU freq:"<<gpu_clk <<"kHz"<<std::endl<< "Average clocks in millisec: "<< clockAvg/(float)gpu_clk << "ms"  << std::endl;        
        //std::cout << "min clk " << *(minmax.first) << std::endl << "max clk " << *(minmax.second) << std::endl;
        //std::cout<< std::endl << "Total clocks in millisec (approx): "<< clockSum/(float)gpu_clk << "ms"<<std::endl; 
   
        count+=1;
        msSum+=item.eventTime;

    } 

    float rb_wb=K_exec*(bytesSize*2 + GRID*sizeof(float));
    std::cout<<std::endl<<"----Effective Bandwidth: "<< (rb_wb/msSum/1e6)<<"GB/s"<<std::endl;

#elif STREAM
    std::cout<<std::endl<<"##########################" <<std::endl;
    std::cout<<"##########STREAM##########" <<std::endl;
    std::cout<<"##########################" <<std::endl;
    const int streamSize = N_size / K_exec ;
    const int streamBytes = streamSize* sizeof(float) ;
    //const int streamBytesInt = streamSize* sizeof(int) ;
    int GRID=streamSize/blockSize;
    int *clocks, *clocks_d;
    clocks=new int[GRID]; 

    cudaEvent_t startEvent, stopEvent;
    checkCuda( cudaEventCreate(&startEvent) );
    checkCuda( cudaEventCreate(&stopEvent) );

    std::cout << "Stream Size \t Stream bytes \t GRID \t BLOCK " << std::endl;
    std::cout << streamSize<<" \t \t " <<streamBytes<< " \t \t " << GRID <<" \t " << blockSize << std::endl;

    //allocate Unified Memory
    /*cudaMallocManaged(&x_d, bytesSize);
    cudaMallocManaged(&x, bytesSize);
    cudaMallocManaged(&clocks, bytesSize);
    cudaMallocManaged(&clocks_d, bytesSize);*/

    cudaMalloc(&x_d, bytesSize);
    cudaMalloc(&clocks_d, GRID*sizeof(int));

    //streams creation
    cudaStream_t stream[K_exec];
    for (int i = 0; i < K_exec; ++i)
        checkCuda(cudaStreamCreate(&stream[i]));

    memset(x, 0, bytesSize);
    memset(cosx, 0, bytesSize);
    memset(clocks, 0, GRID*sizeof(int));
       
        //random generation of X vector
    //std::cout<<"X array : " <<std::endl;    
    for(int i=0; i<N_size;i+=1){
        x[i] = LOW + (float) std::rand() * (HIGH-LOW) / RAND_MAX;   
       // std::cout<< x[i] << ", ";    
    }

    for (int r = 0; r < K_exec; ++r) {
        checkCuda( cudaEventRecord(startEvent,0) );

        for (int i = 0; i < K_exec; ++i) {
            int offset = i * streamSize;
            cudaMemcpyAsync(&x_d[offset], &x[offset], streamBytes, cudaMemcpyHostToDevice, stream[i]);    

            cosKernel<<<GRID, blockSize, 0, stream[i]>>>(M_iter, N_size, x_d, offset, clocks_d);
            //cudaDeviceSynchronize();

            cudaMemcpyAsync( &cosx[offset], &x_d[offset], streamBytes, cudaMemcpyDeviceToHost, stream[i]);
            //cudaMemcpyAsync( &clocks[offset], &clocks_d[offset], streamBytes, cudaMemcpyDeviceToHost, stream[i]);
            cudaMemcpyAsync( &clocks[i], &clocks_d[i], GRID*sizeof(int), cudaMemcpyDeviceToHost, stream[i]);

        }

        checkCuda( cudaEventRecord(stopEvent, 0) );
        checkCuda( cudaEventSynchronize(stopEvent) );
        checkCuda( cudaEventElapsedTime(&ms, startEvent, stopEvent) );
        
        std::cout<<"COSX array : " <<std::endl;  
        for(int j=0; j<N_size;j+=1) 
            std::cout << cosx[j] << ", ";    
        std::cout << std::endl;
        std::cout<< std::endl << "********** ITERATION "<<r<<" **********"<< std::endl;     

        int max=clocks[0],min=clocks[0];
        std::cout <<"Clocks measures"<< std::endl;
        for(int j=0; j<GRID;j+=1) {
            std::cout << clocks[j] << ", ";
            clockSum+=clocks[j];
            if(clocks[j]<min) min=clocks[j];
            if(clocks[j]>max) max=clocks[j];
        }
        clockAvg=clockSum/GRID;
        //auto minmax = std::minmax_element(std::begin(*(clocks)), std::end(*(clocks)));   
        std::cout<< std::endl <<"-------------------------"<< std::endl; 
        std::cout << "GPU freq (kHz) \t Avg clk (ms) \t min clk \t max clk \t event time(ms) "<< std::endl;   
        //std::cout << gpu_clk << " \t " << clockAvg/(float)gpu_clk << " \t "<< *(minmax.first) << " \t " << *(minmax.second) <<std::endl;         
        std::cout << gpu_clk << " \t " << clockAvg/(float)gpu_clk << " \t "<< min << " \t \t " << max <<" \t \t "<< ms<<std::endl;         

        //std::cout<< std::endl << "Total clocks in millisec (approx): "<< clockSum/(float)gpu_clk << "ms"<<std::endl;   
        msSum+=ms;
    }
    //streams destroy
    for (int i = 0; i < K_exec; ++i)
        checkCuda(cudaStreamDestroy(stream[i]));

        float rb_wb=K_exec*(streamBytes*2 + GRID*sizeof(float));
        std::cout<<std::endl<<"----Effective Bandwidth: "<< (rb_wb/msSum/1e6)<<"GB/s"<<std::endl;


#elif STREAMMANAGED
std::cout<<std::endl<<"##################################" <<std::endl;
    std::cout<<"##########STREAM MANAGED##########" <<std::endl;
    std::cout<<"##################################" <<std::endl;
    const int streamSize = N_size / K_exec ;
    const int streamBytes = streamSize* sizeof(float) ;
    //const int streamBytesInt = streamSize* sizeof(int) ;
    int GRID=streamSize/blockSize;
    int *clocks, *clocks_d;
    clocks=new int[GRID]; 
    x_d=new float [N_size];
    cudaEvent_t startEvent, stopEvent;
    checkCuda( cudaEventCreate(&startEvent) );
    checkCuda( cudaEventCreate(&stopEvent) );

    std::cout << "Stream Size \t Stream bytes \t GRID \t BLOCK " << std::endl;
    std::cout << streamSize<<" \t \t " <<streamBytes<< " \t \t " << GRID <<" \t " << blockSize << std::endl;

    //allocate Unified Memory
    /*cudaMallocManaged(&x_d, bytesSize);
    cudaMallocManaged(&x, bytesSize);
    cudaMallocManaged(&clocks, bytesSize);
    cudaMallocManaged(&clocks_d, bytesSize);*/



    //streams creation
    cudaStream_t stream[K_exec];
    for (int i = 0; i < K_exec; ++i)
        checkCuda(cudaStreamCreate(&stream[i]));

    cudaMallocManaged(&x, bytesSize);
    cudaMallocManaged(&clocks, GRID*sizeof(int));

    memset(x, 0, bytesSize);
    memset(clocks, 0, GRID*sizeof(int));

        //random generation of X vector
    //std::cout<<"X array : " <<std::endl;    
    for(int i=0; i<N_size;i+=1){
        x[i] = LOW + (float) std::rand() * (HIGH-LOW) / RAND_MAX;   
        //x_d[i]=x[i];//std::cout<< x[i] << ", ";    
    }

 
       
    

    for (int r = 0; r < K_exec; ++r) {

        checkCuda( cudaEventRecord(startEvent,0) );

        for (int i = 0; i < K_exec; ++i) {
            int offset = i * streamSize;
            //cudaStreamAttachMemAsync(stream[i], &x[offset], 0, cudaMemAttachSingle);    
            //cudaStreamAttachMemAsync(stream[i],&clocks[i], 0, cudaMemAttachSingle);

            cudaStreamAttachMemAsync(stream[i], &x[offset], 0, cudaMemAttachSingle);    
            cudaStreamAttachMemAsync(stream[i],&clocks[i], 0, cudaMemAttachSingle);
            cosKernel<<<GRID, blockSize, 0, stream[i]>>>(M_iter, N_size, x, offset, clocks);
            //cudaDeviceSynchronize();

            //cudaStreamAttachMemAsync( &x[offset], &x_d[offset], streamBytes, cudaMemcpyDeviceToHost, stream[i]);
        }

        checkCuda( cudaEventRecord(stopEvent, 0) );
        checkCuda( cudaEventSynchronize(stopEvent) );
        checkCuda( cudaEventElapsedTime(&ms, startEvent, stopEvent) );
        
        std::cout<< std::endl << "********** ITERATION "<<r<<" **********"<< std::endl;     
        //std::cout<<"X array : " <<std::endl;  
        /*for(int j=0; j<N_size;j+=1) {
            std::cout << x[j] << ", ";
            //x[j]=x_d[j];
        }*/
                
        //std::cout << std::endl;

        //std::copy ( x_d, x_d+N_size, std::back_inserter(*x));
        
        int max=clocks[0],min=clocks[0];
        std::cout <<"Clocks measures"<< std::endl;
        for(int j=0; j<GRID;j+=1) {
            std::cout << clocks[j] << ", ";
            clockSum+=clocks[j];
            if(clocks[j]<min) min=clocks[j];
            if(clocks[j]>max) max=clocks[j];
        }
        clockAvg=clockSum/GRID; 
        std::cout<< std::endl <<"-------------------------"<< std::endl; 
        //std::cout<< std::endl << "Average clocks in millisec: "<< clockAvg/(float)gpu_clk << "ms, GPU freq:"<<gpu_clk <<"kHz"<<std::endl;         
        //std::cout<< std::endl << "Total clocks in millisec (approx): "<< clockSum/(float)gpu_clk << "ms"<<std::endl;   
        //auto minmax = std::minmax_element(std::begin(clocks), std::end(clocks));   
        std::cout << "Avg clk (ms) \t min clk \t max clk \t event time (ms)"<< std::endl;   
        std::cout << clockAvg/(float)gpu_clk << " \t "<< min << " \t \t " << max <<" \t \t "<< ms  <<std::endl;       
        msSum+=ms;
    }
    //streams destroy
    for (int i = 0; i < K_exec; ++i)
        checkCuda(cudaStreamDestroy(stream[i]));

        float rb_wb=K_exec*(streamBytes*2 + GRID*sizeof(float));
        std::cout<<std::endl<<"----Effective Bandwidth: "<< (rb_wb/msSum/1e6)<<"GB/s"<<std::endl;

#endif

    std::cout<<std::endl<<"----Total Events measures: "<< msSum<<"ms"<<std::endl;


    cudaFree(x_d);
    cudaFree(clocks_d);

    return 0;
}