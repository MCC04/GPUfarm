#include <iostream>
#include <math.h>
#include <string.h>  
#include <ctime>
#include <experimental/filesystem>

#include <lodepng.h>
#include <cosFutStr.h>

//#define STREAM: same as compile with -DSTREAM flag
cudaDeviceProp prop;
int BLOCK = 0;
int GRID = 0;

int K_exec = 0;
int M_iter = 0;
int N_size = 0;

int bytesSize;

void printInfos(){
    #ifndef MEASURES
        std::cout<<"Device : "<< prop.name <<std::endl;
        std::cout<<"multiproc num : "<< prop.multiProcessorCount <<std::endl;
        std::cout<<"warp size : "<< prop.warpSize <<std::endl;
            
        std::cout << "Items number \t Host iterations \t Kernel iterations " << std::endl;
        std::cout << N_size<<" \t \t \t " << K_exec<< " \t \t \t " << M_iter << std::endl;
 
    #endif     
}


void printTotalTimes(float eventsTime, float hostTime ){
    int rb_wb = bytesSize*2 + GRID*sizeof(float); //?????
    std::cout<<std::endl<<"----Total Device Events measures: "<< eventsTime<<"ms"<<std::endl;
    std::cout<<std::endl<<"----Total Host measures: "<< hostTime <<"ms"<<std::endl;
    std::cout<<std::endl<<"----Effective Bandwidth: "<< (rb_wb/eventsTime/1e6)<<"GB/s"<<std::endl;     
}


void printClocks(int *clocks, int size){    
    std::cout<< std::endl<<"Clocks measures"<< std::endl;

    std::cout <<"-------------------------"<< std::endl;
    if (size>2){
        int max = clocks[0],min = clocks[0];
        int clockSum = 0;
        for(int j = 0; j<size; ++j) {
            std::cout << clocks[j] << ", ";
            clockSum += clocks[j];
            if(clocks[j]<min) min = clocks[j];
            if(clocks[j]>max) max = clocks[j];
        }
        int clockAvg = clockSum/size;
        std::cout <<std::endl<< "Avg clk \t min clk \t max clk "<< std::endl;   
        std::cout << clockAvg <<" \t "<< min <<" \t "<< max;
    }
    else if(size>=1){
        for(int j = 0; j<size; ++j) 
            std::cout << clocks[j] << ", ";
    }
    else{
        std::cout <<std::endl<< "No clocks were sampled."<< std::endl;   
    }
    std::cout<<std::endl<<"-------------------------"<< std::endl;
}


void printCos(float *cosx, int size){    
    std::cout<<"COSX array : " <<std::endl;  
    for(int j=0; j<size;++j) 
        std::cout << cosx[j] << ", ";    
    std::cout << std::endl;  
}


void printMeasures(std::string label, float msTot, float millis, int devId){
    std::cout<< label <<","<< msTot <<","<< millis <<","        //outputs
            << M_iter <<","<< N_size <<"," << K_exec <<","      //inputs
            << devId <<","<< BLOCK <<","<< GRID << std::endl;   //GPU infos
}


int main(int argc, char **argv){  
    std::srand(static_cast <unsigned> (time(NULL)));

    const int nStreams =  3;    
    float msTot = 0.0f;    
    int gpu_clk = 1; 
    std::string label;
    std::chrono::system_clock::time_point start,end;
    std::chrono::duration<double, std::milli> millis;  
    cudaEvent_t startEvent, stopEvent;

    //args
    int devId = atoi(argv[1]); 
    BLOCK = atoi(argv[2]);
    K_exec = atoi(argv[3]);
    M_iter = atoi(argv[4]);
    N_size = atoi(argv[5]);

    int chunk = N_size/K_exec;
    if(chunk<BLOCK){
        std::cerr<<"The chunk size is smaller than Block size."
                    <<std::endl<<"Please, enter more elements (N) or less chunks (K)."<<std::endl;
        return -1;
    }
    bytesSize = chunk*sizeof(float); 

    //grid setting
    #ifdef LOWPAR
        GRID = 1;
        label = "LOW";
    #else
        label = "";
        GRID = ceil(chunk/BLOCK); //then make test on non divisible factors 
    #endif


    #ifdef EMPTY
        std::cout <<"*";
        for (int i = 0; i < K_exec; ++i) {  
            msTot = emptyKer();
            std::cout <<msTot<< ",";     
        }
        std::cout <<std::endl; 
        return 0;
    #endif

    //device id setting
    gpuErrchk( cudaDeviceGetAttribute(&gpu_clk, cudaDevAttrClockRate, devId) );    
    gpuErrchk( cudaSetDevice(devId) );
    gpuErrchk( cudaGetDeviceProperties(&prop, devId) );     
    #ifndef MEASURES
        printInfos(); 
    #endif

/*** FUTURE ***/
#ifdef FUTURE
    //std::vector<double> bandW;
    label += "FUTURE";    
    std::vector<std::future<hostData_t>> futures;
    std::vector<hostData_t> getDatas;   

    start = std::chrono::system_clock::now();

    //host pinned memory
    hostData_t output;
    float *x;
    gpuErrchk( cudaMallocHost((void **)&x, N_size*sizeof(float)) ); //pinned x
    gpuErrchk( cudaMallocHost((void **)&output.x, bytesSize) ); //pinned x   
    gpuErrchk( cudaMallocHost((void **)&output.clocks, GRID*sizeof(int)) ); //pinned x  

    //device memory
    float *x_d;
    int *clocks_d;    
    gpuErrchk( cudaMalloc((void **)&x_d, bytesSize) ); 
    gpuErrchk( cudaMalloc((void **)&clocks_d, GRID*sizeof(int)) );
    
    //stream array and events creation 
    cudaStream_t streams[nStreams];
    streamCreate(streams, nStreams);    
    createAndStartEvent(&startEvent, &stopEvent);

    //kernel launcher
    futures = cosKerFuture(M_iter, chunk, output, x, x_d, clocks_d, streams, nStreams, 0 );
  
    //data gathering
    for(auto &e : futures) 
        getDatas.push_back(e.get()); 

    
    msTot = endEvent(&startEvent, &stopEvent);
    streamDestroy(streams, nStreams);

    end = std::chrono::system_clock::now();

    //print results
    #ifndef MEASURES
        for(auto item : getDatas){  
            printClocks(item.clocks, GRID);
            printCos(item.x, chunk);      
        } 
    #else
        millis = end-start;
        printMeasures(label, msTot, millis.count(), devId);
    #endif

    //free Host and Device space
    cudaFreeHost(x);
    cudaFreeHost(output.x);
    cudaFreeHost(output.clocks);
    cudaFree(x_d);
    cudaFree(clocks_d);


/*** STREAM ***/
#elif STREAM
    const int streamBytes = chunk*sizeof(float) ;

    start = std::chrono::system_clock::now();
    //host pinned memory
    float *x, *cosx;
    int *clocks;
    gpuErrchk( cudaMallocHost((void **)&x, N_size*sizeof(float)) ); //pinned x    
    gpuErrchk( cudaMallocHost((void **)&cosx, N_size*sizeof(float)) ); //pinned cosx
    gpuErrchk( cudaMallocHost((void **)&clocks, GRID*sizeof(int)) ); //pinned clocks

    //device memory
    float *x_d; 
    int *clocks_d;
    gpuErrchk( cudaMalloc((void**)&x_d, streamBytes) );
    gpuErrchk( cudaMalloc((void**)&clocks_d, GRID*sizeof(int)) );   

    //stream array and events creation 
    cudaStream_t streams[nStreams];
    streamCreate(streams, nStreams);
    createAndStartEvent(&startEvent, &stopEvent);

    for (int i = 0; i < K_exec; ++i) {  
        int k = i%nStreams;
        randomArray(x+i*chunk,chunk);
       
        cosKerStream(M_iter,chunk, x+(i*chunk), cosx+(i*chunk), x_d, clocks, clocks_d, streams[k], streamBytes, 0);        
        #ifndef MEASURES
            printCos(cosx+i*chunk, chunk);
        #endif
    }    
    msTot = endEvent(&startEvent, &stopEvent);
    streamDestroy(streams,nStreams);    

    end = std::chrono::system_clock::now();

    //print results
    #ifdef MEASURES
        millis = end-start;
        label += "STREAM";
        printMeasures(label, msTot, millis.count(), devId);
    #endif
    
    //free Host and Device space
    cudaFreeHost(x);
    cudaFreeHost(cosx);
    cudaFreeHost(clocks);
    cudaFree(x_d);
    cudaFree(clocks_d);


/*** MANAGED ***/
#elif MANAGED
    const int streamBytes = chunk* sizeof(float);

    int *clocks = new int[GRID]; //sarà da fare pinned anche qua??
    float *cosx = new float[chunk];
    int bytesX = chunk*sizeof(float);
    int bytesClocks = GRID*sizeof(int);
   
    
    start = std::chrono::system_clock::now();
    //stream array and events creation
    cudaStream_t *stream = streamCreate(nStreams);
    //cudaEvent_t startEvent, stopEvent;
    /*gpuErrchk( cudaEventCreate(&startEvent) );
    gpuErrchk( cudaEventCreate(&stopEvent) );
    gpuErrchk( cudaEventRecord(startEvent,0) );*/
    createAndStartEvent(&startEvent, &stopEvent);
    //unified memory
    cudaMallocManaged(&x, bytesX);
    cudaMallocManaged(&cosx, bytesX);
    cudaMallocManaged(&clocks, bytesClocks);

    for (int i = 0; i < K_exec; ++i) {   
        int k = i%nStreams;

        cosKerStream(M_iter, chunk, x, cosx, clocks, 0, stream[k]);

        #ifndef MEASURES
            printCos(cosx,chunk);
            printClocks(clocks);
        #endif
    }
    //events stop and stream
    /*gpuErrchk( cudaEventRecord(stopEvent, 0) );
    gpuErrchk( cudaEventSynchronize(stopEvent) );
    gpuErrchk( cudaEventElapsedTime(&msTot, startEvent, stopEvent) );*/
    msTot = endEvent(&startEvent, &stopEvent);
    streamDestroy(stream,nStreams);
    end = std::chrono::system_clock::now();
//sistema le print per managed

    #ifdef MEASURES
        millis = end-start;
        label + =  "MANAGED";
        printMeasures(label, msTot, millis.count(), devId);
        //std::cout<< label <<","<< msTot <<","<< millis.count() <<","             //outputs
          //                  << M_iter <<","<< N_size <<"," << K_exec <<","      //inputs
            //                << devId <<","<< BLOCK <<","<< GRID << std::endl;   //GPU infos
    #endif

#endif

#ifndef MEASURES
    printTotalTimes(msTot, (end-start).count());
#endif

    cudaDeviceReset();
    return 0;
}

