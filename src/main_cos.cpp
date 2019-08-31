#include <iostream>
#include <math.h>
#include <string.h>  
#include <ctime>
#include <experimental/filesystem>

#include <lodepng.h>
#include <cosFutStr.h>

#define HIGH 500.0f //#define is the same as compile with -DHIGH
#define LOW -500.0f

cudaDeviceProp prop;
int BLOCK = 0;
int GRID = 0;

//int K_exec = 0;
int M_iter = 0;
int N_size = 0;

int bytesSize;

void printInfos(){
    #ifndef MEASURES
        std::cout<<"Device : "<< prop.name <<std::endl;
        std::cout<<"multiproc num : "<< prop.multiProcessorCount <<std::endl;
        std::cout<<"warp size : "<< prop.warpSize <<std::endl;
            
        std::cout << "Items number \t Kernel iterations " << std::endl;
        std::cout << N_size<< " \t \t \t " << M_iter << std::endl;
 
    #endif     
}


void printTotalTimes(float eventsTime, float hostTime ){
    int rb_wb = bytesSize*2 + GRID*sizeof(float); //?????
    std::cout<<std::endl<<"----Total Device Events measures: "<< eventsTime<<"ms"<<std::endl;
    std::cout<<std::endl<<"----Total Host measures: "<< hostTime <<"ms"<<std::endl;
    std::cout<<std::endl<<"----Effective Bandwidth: "<< (rb_wb/eventsTime/1e6)<<"GB/s"<<std::endl;     
}


/* inline void printClocks(int *clocks, int size){    
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
*/

inline void printCos(float *cosx, int size){    
    std::cout<<"COSX array : " <<std::endl;  
    for(int j=0; j<size;++j) 
        std::cout << cosx[j] << ", ";    
    std::cout << std::endl;  
}


void printMeasures(std::string label, float msTot, float millis, int devId, int strNum, int chunkSize){
    std::cout<< label <<","<< msTot <<","<< millis <<","<< chunkSize <<","      //outputs
            << N_size <<"," << M_iter <<","<< strNum <<","          //inputs
            << devId <<","<< BLOCK <<","<< GRID << std::endl;                   //GPU infos
}


int main(int argc, char **argv){  
    std::srand(static_cast <unsigned> (time(NULL)));

    float msTot = 0.0f;    
    std::string label;
    std::chrono::system_clock::time_point start,end;
    std::chrono::duration<double, std::milli> millis;  
    cudaEvent_t startEvent, stopEvent;

    //args
    if (argc!=7){
        std::cerr << "Usage: " << argv[0] << "deviceID, BLOCK, N, M, cuStr, strNum" << std::endl;
        return 1;
    }
    int devId = atoi(argv[1]); 
    BLOCK = atoi(argv[2]);
    N_size = atoi(argv[3]);
    M_iter = atoi(argv[4]);
    bool cuStr = atoi(argv[5]);
    int strNum = atoi(argv[6]);

    bytesSize = N_size*sizeof(float); 
    #ifdef LOWPAR
        label = "LOW";
    #else
        label = "";       
    #endif

    // Device ID and properties
    gpuErrchk( cudaSetDevice(devId) );
    gpuErrchk( cudaGetDeviceProperties(&prop, devId) );  
    const int maxThreads = prop.maxThreadsPerMultiProcessor;    

    #ifndef MEASURES 
        printInfos(); 
    #endif

/**** STREAM PARALLEL ****/
#ifdef STREAM    
    int chunkSize;
    int nStreams=0;
    float *x, *cosx, *x_d;
    start = std::chrono::system_clock::now();
    // Grid and Block setting
    #ifdef LOWPAR
        GRID = 1;
    #else
        GRID = maxThreads/BLOCK;  
    #endif
    chunkSize = BLOCK*GRID;
    
    if (!cuStr) {// NO CUDA STREAMS
        // Host alloc
        x = (float *) malloc(bytesSize);
        cosx = (float *) malloc(bytesSize);
        // Device alloc
        gpuErrchk( cudaMalloc((void**)&x_d, chunkSize*sizeof(float)) );
        // Events creation and start 
        createAndStartEvent(&startEvent, &stopEvent);
        
        for (int i = 0; i < N_size/chunkSize; ++i) {  
            // Random chunk
            randomArray(x+(i*chunkSize),chunkSize);
            // Kernel launcher           
            cosine(M_iter,chunkSize, x+(i*chunkSize), cosx+(i*chunkSize), x_d);            
            // Print results
            #ifndef MEASURES
                printCos(cosx+i*chunkSize, chunkSize);
            #endif                
        } 
        msTot = endEvent(&startEvent, &stopEvent);
    }
    else { // CUDA STREAMS
        if (strNum>1)
            nStreams = strNum;
        else
            nStreams = prop.multiProcessorCount;
        const int streamBytes = chunkSize*sizeof(float) ;

        // Host pinned mem
        gpuErrchk( cudaMallocHost((void **)&x, bytesSize) );  
        gpuErrchk( cudaMallocHost((void **)&cosx, bytesSize) ); 
        // Device alloc
        int totStreamSize = nStreams*streamBytes;
        gpuErrchk( cudaMalloc((void**)&x_d, totStreamSize) );
        // Stream and events creation 
        cudaStream_t streams[nStreams];
        streamCreate(streams, nStreams);
        createAndStartEvent(&startEvent, &stopEvent);
  
        for (int i = 0; i < N_size/chunkSize; ++i) {  
            int k = i%nStreams;
            int strOffs = k*chunkSize;
            randomArray(x+i*chunkSize, chunkSize);
        
            streamCosine( M_iter, chunkSize, x+(i*chunkSize), cosx+(i*chunkSize), x_d+strOffs, 
                            streams[k], streamBytes);        
            
            
        }         
        msTot = endEvent(&startEvent, &stopEvent);
        #ifndef MEASURES
            cudaDeviceSynchronize();
            printCos(cosx, N_size);
        #endif
        streamDestroy(streams,nStreams); 
    }
    end = std::chrono::system_clock::now();
    // Print results
    #ifdef MEASURES
        millis = end-start;
        label += "STREAM";
        printMeasures(label, msTot, millis.count(), devId, nStreams, chunkSize);
    #endif    
    // Free mem
    cudaFreeHost(x);
    cudaFreeHost(cosx);
    cudaFree(x_d);

/**** DATA PARALLEL ****/
#elif DATAPAR
    start = std::chrono::system_clock::now();

    float *x, *cosx, *x_d;
    // Host alloc
    x = (float *) malloc(bytesSize);
    cosx = (float *) malloc(bytesSize);
    // Device alloc
    gpuErrchk( cudaMalloc((void**)&x_d, bytesSize) );
    // Data init
    randomArray(x,N_size);
    // Events creation and start
    createAndStartEvent(&startEvent, &stopEvent);
    // Kernel launcher
    float msKer = optimalCosKer(M_iter, N_size, x, cosx, x_d); 

    msTot = endEvent(&startEvent, &stopEvent);
    end = std::chrono::system_clock::now();
    // Print results
    #ifndef MEASURES
        printCos(cosx, N_size);
    #else
        millis = end-start;
        label += "DATAPAR";
        printMeasures(label, msKer, millis.count(), devId, 0, N_size);
    #endif    
    // Free mem
    cudaFreeHost(x);
    cudaFreeHost(cosx);
    cudaFree(x_d);


/*** FUTURE ***/
#elif FUTURE
    if (strNum>1)
        nStreams = strNum;
    else
        nStreams = prop.multiProcessorCount;
    //const int nStreams = prop.multiProcessorCount;
    label += "FUTURE";    
    std::vector<std::future<float *>> futures;
    std::vector<float *> getDatas;  
    float *x_d, *x, *cosx;

    // Grid and Block setting
    #ifdef LOWPAR
        GRID = 1;
    #else
        GRID = maxThreads/BLOCK;  
    #endif
    int chunkSize = BLOCK*GRID;

    const int streamBytes = chunkSize*sizeof(float) ;
    const int totStreamSize = nStreams*streamBytes;

    start = std::chrono::system_clock::now();
    // Host pinned mem
    gpuErrchk( cudaMallocHost((void **)&x, bytesSize) ); 
    gpuErrchk( cudaMallocHost((void **)&cosx, bytesSize) );  
    // Device mem    
    gpuErrchk( cudaMalloc((void **)&x_d, totStreamSize) );    
    // Stream array and events creation 
    cudaStream_t streams[nStreams];
    streamCreate(streams, nStreams);    
    createAndStartEvent(&startEvent, &stopEvent);

    // Kernel launcher
    futures = streamFutureCosine(M_iter, chunkSize, cosx, x, x_d, streams, nStreams );

    // Data gathering
    for(auto &e : futures) 
        getDatas.push_back(e.get()); 
    // Event end and stream destroy
    msTot = endEvent(&startEvent, &stopEvent);
    streamDestroy(streams, nStreams);
    end = std::chrono::system_clock::now();
    // Print results
    #ifndef MEASURES
        cudaDeviceSynchronize();
        for(auto item : getDatas)
            printCos(item, chunkSize);      
    #else
        millis = end-start;
        printMeasures(label, msTot, millis.count(), devId, nStreams, chunkSize);
    #endif
    // Free mem
    cudaFreeHost(x);
    cudaFreeHost(cosx);
    cudaFree(x_d);

/*** MANAGED ***/
#elif MANAGED
    const int streamBytes = chunk* sizeof(float);
    float *cosx, *x;
    //int *clocks;
    int bytesClocks = GRID*sizeof(int);   
    
    start = std::chrono::system_clock::now();

    //stream array and events creation 
    cudaStream_t streams[nStreams];
    streamCreate(streams, nStreams);
    createAndStartEvent(&startEvent, &stopEvent);

    //unified memory
    cudaMallocManaged(&x, streamBytes*nStreams);
    cudaMallocManaged(&cosx, streamBytes*nStreams);
    //cudaMallocManaged(&clocks, bytesClocks*nStreams);

    for (int i = 0; i < K_exec; ++i) {   
        int k = i%nStreams;
        int strOffs = k*chunk;

        cosKerStream(M_iter, chunk, x+strOffs, cosx+strOffs, clocks+(k*GRID), 0, streams[k]);

        #ifndef MEASURES
            printCos(cosx,chunk);
            printClocks(clocks,GRID);
        #endif
    }
    //events stop and stream destroy
    msTot = endEvent(&startEvent, &stopEvent);
    streamDestroy(streams,nStreams);
    end = std::chrono::system_clock::now();

    #ifdef MEASURES
        millis = end-start;
        label +=  "MANAGED";
        printMeasures(label, msTot, millis.count(), devId);
    #endif
#endif

#ifndef MEASURES
    printTotalTimes(msTot, (end-start).count());
#endif

    cudaDeviceReset();
    return 0;
}