#include <iostream>
#include <math.h>
#include <stdlib.h>
#include <assert.h>
#include <string.h>  
#include <cstdlib>
#include <algorithm>
#include <ctime>
#include <vector>
#include <future>
#include <iterator>
#include <experimental/filesystem>

#include <lodepng.h>
#include <cosFutStr.h>
//#define STREAM: is the same as compile with -DSTREAM flag

cudaDeviceProp prop;
int BLOCK=0;
int GRID=0;

int K_exec=0;
int M_iter=0;
int N_size=0;

int bytesSize;

void printInfos(){
    #ifndef MEASURES
        std::cout<<"Device : "<< prop.name <<std::endl;
        std::cout<<"multiproc num : "<< prop.multiProcessorCount <<std::endl;
        std::cout<<"warp size : "<< prop.warpSize <<std::endl;
            
        std::cout << "Items number \t Host iterations \t Kernel iterations " << std::endl;
        std::cout << N_size<<" \t \t \t " << K_exec<< " \t \t \t " << M_iter << std::endl;
    #else
        std::cout << N_size<<"," << K_exec<< "," << M_iter<< "," <<GRID<< "," <<BLOCK << std::endl;
    #endif     
}

void printResults(float ms){
    float rb_wb=bytesSize*2 + GRID*sizeof(float); 
    std::cout <<"*"<< ms<< ","<< (rb_wb/ms/1e6)<<std::endl; 
}

void printTotalTimes(float eventsTime,  float hostTime ){
    #ifdef MEASURES
        std::cout<<std::endl<<"$"<< eventsTime<<","<<hostTime<<std::endl;
    #else
        std::cout<<std::endl<<"----Total Device Events measures: "<< eventsTime<<"ms"<<std::endl;
        std::cout<<std::endl<<"----Total Host measures: "<< hostTime <<"ms"<<std::endl;
    #endif
}

void printAll(float *cosx, int *clocks, float ms){    
    std::cout<<std::endl<<"COSX array : " <<std::endl;  
    for(int j=0; j<N_size;j+=1) 
        std::cout << cosx[j] << ", ";    
    std::cout << std::endl;
    std::cout <<"Clocks measures"<< std::endl;

    int max=clocks[0],min=clocks[0];
    int clockSum=0;
    for(int j=0; j<GRID;j+=1) {
        std::cout << clocks[j] << ", ";
        clockSum+=clocks[j];
        if(clocks[j]<min) min=clocks[j];
        if(clocks[j]>max) max=clocks[j];
    }
    int clockAvg=clockSum/GRID;
    int rb_wb=bytesSize*2 + GRID*sizeof(float);        

    std::cout<< std::endl <<"-------------------------"<< std::endl; 
    std::cout << 
    "Avg clk (ms) \t min clk \t max clk \t event time(ms) "<< std::endl;   
    std::cout << min << " \t " << max <<" \t "<< ms<<std::endl; 
    std::cout<<std::endl<<"----Effective Bandwidth: "<< (rb_wb/ms/1e6)<<"GB/s"<<std::endl;      
}






#define HIGH 500.0f
#define LOW -500.0f


void streamGenerator(int dim, float *buffer){



    #ifndef MEASURES
            std::cout<<std::endl<< "BUFFER: "<<std::endl;  
    #endif
    for(int i=0; i<dim;++i){
        buffer[i] = LOW + (float) std::rand() * (HIGH-LOW) / RAND_MAX;   
        #ifndef MEASURES
            std::cout<< buffer[i] << ", ";  
        #endif
    }
}







int main(int argc, char **argv){   

    std::srand(static_cast <unsigned> (time(NULL)));

    int gpu_clk=1;
    float clockSum=0.0, clockAvg=0.0;
    float msSum=0.0, rb_wb=0.0; 
    std::chrono::system_clock::time_point start,end;

    int devId = atoi(argv[1]);
    #ifdef LOWPAR
        BLOCK=2;
        GRID=1;
    #else
        BLOCK = atoi(argv[2]);
    #endif
    K_exec = atoi(argv[3]);
    M_iter = atoi(argv[4]);
    N_size = atoi(argv[5]);

    int buffSize=atoi(argv[6]);
    float p=atof(argv[7]);
    float q=atof(argv[8]);


    #ifdef EMPTY
        std::cout <<"*";
        for (int i = 0; i < K_exec; ++i) {  
            float ms=emptyKer();
            std::cout <<ms<< ",";     
        }
        std::cout <<std::endl; 

        return 0;
    #endif

    bytesSize = N_size*sizeof(float); auto gpuRet=futGpu.get();
    float *x=new float [N_size];      
     
    checkCuda(cudaDeviceGetAttribute(&gpu_clk, cudaDevAttrClockRate, devId));    
    checkCuda( cudaSetDevice(devId) );
    checkCuda( cudaGetDeviceProperties(&prop, devId));     


/*
* AUTO-SCHEDULER
*/
#ifdef AUTOSCHED
    std::chrono::time_point<std::chrono::system_clock> startTotal, endTotal;

    float totCpu=0, totGpu=0; 
    float *bufferIn=new float [buffSize]; 
    float *bufferOut=new float [buffSize];

    std::vector<std::future<my_struct>> futures;
    std::future<my_struct> futGpu;
    std::future<my_struct> futCpu;
    cudaEvent_t startEvent, stopEvent;
    checkCuda( cudaEventCreate(&startEvent) );
    checkCuda( cudaEventCreate(&stopEvent) );
    cudaStream_t *stream=streamCreate(K_exec);

    int *clocks_d;
    float *x_d; 
    checkCuda(cudaMalloc(&x_d, buffSize*sizeof(float))); 
    checkCuda(cudaMalloc(&clocks_d, buffSize/BLOCK*sizeof(int)));
    int strId=0;

    startTotal=std::chrono::system_clock::now();

    for(int i=0; i<N_size; i+=buffSize){
        streamGenerator(buffSize,bufferIn);

        //COMPUTE CPU CHUNK SIZE USING P        
        int cpuChunk = ceil(buffSize*p);
        int gpuChunk = buffSize - cpuChunk;

        #ifdef MEASURES
            std::cout<< std::endl<<p<<","<<q <<",";
        #endif

        //***CPU***         
        futCpu = std::async(std::launch::async,
        [&]() {
            std::chrono::time_point<std::chrono::system_clock> startChrono, endChrono;

            startChrono=std::chrono::system_clock::now();
            my_struct _xs;
            _xs.x_vect=new float[cpuChunk];
            
            for(int k=0; k<cpuChunk; ++k){
                _xs.x_vect[k] = cos(bufferIn[k]);
                for(int j=0; j<M_iter; ++j)      
                    _xs.x_vect[k] = cos(_xs.x_vect[k]);                 
            }
            endChrono=std::chrono::system_clock::now();        
            std::chrono::duration<double,std::milli> elapsed =endChrono - startChrono;
            _xs.eventTime = elapsed.count();
            return _xs;
        });        
        

        //***GPU***
        strId = i % K_exec;    
        GRID=ceil(gpuChunk/BLOCK)+1; //grid stride?
 
        futGpu = std::async(std::launch::deferred,
            [&]() { 
                //checkCuda(cudaMalloc(&x_d, gpuChunk*sizeof(float))); 
                //checkCuda(cudaMalloc(&clocks_d, GRID*sizeof(int)));
                my_struct _xs;
                _xs.clocks=new int[GRID];
                _xs.x_vect=new float[gpuChunk];
                std::copy(bufferIn+cpuChunk, bufferIn+cpuChunk+gpuChunk-1, _xs.x_vect);
                cosKer(&_xs, x_d, clocks_d,gpuChunk*sizeof(float), startEvent, stopEvent, stream[strId]);
                //cudaFree(x_d);
                //cudaFree(clocks_d);
                return _xs;
            });

        auto cpuRet=futCpu.get();
        auto gpuRet=futGpu.get();


        //REBUILD BUFFEROUT
        std::copy(cpuRet.x_vect, cpuRet.x_vect+cpuChunk, bufferOut);
        std::copy(gpuRet.x_vect, gpuRet.x_vect+gpuChunk, bufferOut+cpuChunk);

        totCpu+=cpuRet.eventTime;
        totGpu+=gpuRet.eventTime;

        //COMPUTE NEW P AND Q        
        float tpCpu = cpuRet.eventTime/(M_iter*cpuChunk);
        float tpGpu = gpuRet.eventTime/(M_iter*gpuChunk);

        float sum=tpCpu+tpGpu;
        tpCpu/=sum;
        tpGpu/=sum;

        p=1-tpCpu;
        q=1-p;

        #ifndef MEASURES
            std::cout << std::endl;
            std::cout << std::endl << "********** ITERATION "<<i<<" **********"<< std::endl;  
            std::cout << "OUT BUFFER : " <<std::endl;  
            for(int j=0; j<buffSize;++j) 
                std::cout << bufferOut[j] << ", ";    
            
            std::cout<<std::endl<< "CPU elapsed + GPU eventTime: "
                <<cpuRet.eventTime<<" ms, "<<gpuRet.eventTime<< std::endl;
            std::cout<<std::endl<< "P + Q: "
                <<p<<", "<<q<< std::endl;
        #else
            std::cout<<cpuRet.eventTime<<","<<gpuRet.eventTime; 
        #endif
    }

    streamDestroy(stream,K_exec); 
    cudaFree(x_d);
    cudaFree(clocks_d);

    endTotal=std::chrono::system_clock::now();        
    std::chrono::duration<double,std::milli> hostCompT =endTotal - startTotal;
    #ifdef MEASURES
    std::cout<<std::endl<<"*"<<hostCompT.count()<<std::endl;
    #endif










#elif FUTURE
    std::cout<<std::endl<<std::endl<<"#FUTURE,";
    #ifndef LOWPAR
        GRID=N_size/BLOCK; 
    #endif
    
    printInfos();
    std::vector<my_struct> getDatas;   
    start=std::chrono::system_clock::now();

    cosKer(getDatas, bytesSize);

    std::vector<double> bandW;

    #ifdef MEASURES
        std::cout << std::endl << "*";
    #endif
    for(auto item : getDatas){  
        #ifndef MEASURES
            printAll(item.x_vect, item.clocks, item.eventTime);
        #else
            std::cout<< item.eventTime <<",";
            float rb_wb=bytesSize*2 + GRID*sizeof(float); 
            bandW.push_back(rb_wb/item.eventTime/1e6);
        #endif 
        msSum+=item.eventTime;
    } 
    #ifdef MEASURES
    std::cout <<std::endl<<"@";
    for(auto b : bandW){ 
        std::cout<< b <<",";
    }
    #endif
    end=std::chrono::system_clock::now();

#elif STREAM

    int *clocks_d,*clocks;
    float *cosx=new float[N_size];
    const int streamSize = N_size;
    const int streamBytes = streamSize* sizeof(float) ;
    #ifndef LOWPAR
        GRID=streamSize/BLOCK; 
    #endif
    clocks=new int[GRID]; 

    std::cout<<std::endl<<std::endl<<"#STREAM,";
    printInfos();    

    start=std::chrono::system_clock::now();

    cudaEvent_t startEvent, stopEvent;
    checkCuda( cudaEventCreate(&startEvent) );
    checkCuda( cudaEventCreate(&stopEvent) );

    float *x_d;
    float ms=0;
    cudaMalloc(&x_d, bytesSize);
    cudaMalloc(&clocks_d, GRID*sizeof(int));
   
    cudaStream_t *stream=streamCreate(K_exec);

    for (int i = 0; i < K_exec; ++i) {  
        ms=0;   
        randomArray(x,N_size);

        checkCuda( cudaEventRecord(startEvent,0) );
        
        cudaMemcpyAsync(x_d, x, streamBytes, cudaMemcpyHostToDevice, stream[i]);          
        cosKerStream(M_iter,N_size, x_d, clocks_d, 0, stream[i]);
        cudaMemcpyAsync( cosx, x_d, streamBytes, cudaMemcpyDeviceToHost, stream[i]);
        cudaMemcpyAsync( clocks, clocks_d, GRID*sizeof(int), cudaMemcpyDeviceToHost, stream[i]);

        checkCuda( cudaEventRecord(stopEvent, 0) );
        checkCuda( cudaEventSynchronize(stopEvent) );
        checkCuda( cudaEventElapsedTime(&ms, startEvent, stopEvent) );
   
        #ifndef MEASURES
            printAll(cosx, clocks, ms);
        #else
            printResults(ms);
        #endif   

        msSum+=ms;
    }    
    streamDestroy(stream,K_exec);    
    delete [] cosx;
    delete [] clocks;
    end=std::chrono::system_clock::now();

#elif MANAGED
    const int streamSize = N_size ;
    const int streamBytes = streamSize* sizeof(float) ;

    float ms=0.0;
    float msTot=0.0;
    #ifndef LOWPAR
        GRID=streamSize/BLOCK;
    #endif
    int *clocks;
    clocks=new int[GRID]; 
    float *cosx=new float[N_size];
    int bytesX = N_size*sizeof(float);
    int bytesClocks = GRID*sizeof(int);
   
    std::cout<<std::endl<<std::endl<<"#MANAGED,";
    printInfos();
       
    start=std::chrono::system_clock::now();
    
    cudaEvent_t startEvent, stopEvent;  
    checkCuda( cudaEventCreate(&startEvent) );
    checkCuda( cudaEventCreate(&stopEvent) );  

    cudaEvent_t startTot, stopTot;  
    checkCuda( cudaEventCreate(&startTot) );
    checkCuda( cudaEventCreate(&stopTot) ); 

    cudaStream_t *stream=streamCreate(K_exec);

    checkCuda( cudaEventRecord(startTot,0) );
    cudaMallocManaged(&x, bytesX);
    cudaMallocManaged(&cosx, bytesX);
    cudaMallocManaged(&clocks, bytesClocks);

    checkCuda( cudaEventRecord(stopTot, 0) );
    checkCuda( cudaEventSynchronize(stopTot) );
    checkCuda( cudaEventElapsedTime(&msSum, startTot, stopTot) );


    for (int i = 0; i < K_exec; ++i) {   
        ms=cosKerStream(startEvent,stopEvent,M_iter, N_size,
                        x, cosx, clocks, 0, stream[i]);

        #ifndef MEASURES
            printAll(cosx, clocks, ms);
        #else
            printResults(ms);
        #endif

        msTot+=ms;
    }

  
    msSum+=msTot;

    streamDestroy(stream,K_exec);
    end=std::chrono::system_clock::now();

#endif
    printTotalTimes(totCpu,  totGpu);

    #ifndef MANAGED
        delete [] x;
    #endif
    #ifdef STREAM 
        cudaFree(x_d);
        cudaFree(clocks_d);
    #elif STREAMMANAGED
        cudaFree(x);
        cudaFree(clocks);
    #endif

    return 0;
}

