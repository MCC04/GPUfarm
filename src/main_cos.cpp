#include <iostream>
#include <math.h>
#include <string.h>  
#include <ctime>
#include <experimental/filesystem>

#include <lodepng.h>
#include <cosFutStr.h>

#define HIGH 500.0f
#define LOW -500.0f

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


inline void printClocks(int *clocks, int size){    
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


inline void printCos(float *cosx, int size){    
    std::cout<<"COSX array : " <<std::endl;  
    for(int j=0; j<size;++j) 
        std::cout << cosx[j] << ", ";    
    std::cout << std::endl;  
}


void printMeasures(std::string label, float msTot, float millis, int devId, int strNum, int hyb, int chunkSize){
    std::cout<< label <<","<< msTot <<","<< millis <<","<< chunkSize <<","      //outputs
            << N_size <<"," << M_iter <<","<< strNum <<","<< hyb <<","          //inputs
            << devId <<","<< BLOCK <<","<< GRID << std::endl;                   //GPU infos
}


int main(int argc, char **argv){  
    std::srand(static_cast <unsigned> (time(NULL)));

    const int maxThreads = 2048;
   
    float msTot = 0.0f;    
    int gpu_clk = 1; 
    std::string label;
    std::chrono::system_clock::time_point start,end;
    std::chrono::duration<double, std::milli> millis;  
    cudaEvent_t startEvent, stopEvent;

    //args
    if (argc!=7){
        return 1;
    }
    int devId = atoi(argv[1]); 
    BLOCK = atoi(argv[2]);
    N_size = atoi(argv[3]);
    M_iter = atoi(argv[4]);
    const int nStreams = atoi(argv[5]);
    int hyb = atoi(argv[6]);

    int chunk = N_size;
    bytesSize = chunk*sizeof(float); 

    #ifdef LOWPAR
        label = "LOW";
    #else
        label = "";       
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


#ifdef STREAM    
    int chunkSize = 1;
    start = std::chrono::system_clock::now();

    float *x, *cosx;
    int *clocks;
    float *x_d; 
    int *clocks_d;

    #ifdef LOWPAR
        GRID = 1;
        if (!hyb)
        {
            BLOCK = 32;
            chunkSize=1;
        }
        else
        {
            chunkSize = BLOCK*GRID;
        }
        
    #else
        if (hyb)
            GRID = 56;
        else
            GRID = maxThreads/BLOCK;  
        chunkSize = BLOCK*GRID;
    #endif
    
    if (nStreams==0)
    {           
        x = (float *) malloc(N_size*sizeof(float));
        cosx = (float *) malloc(N_size*sizeof(float));
        clocks = (int *) malloc(GRID*sizeof(int));

        //device memory
        gpuErrchk( cudaMalloc((void**)&x_d, chunkSize*sizeof(float)) );
        gpuErrchk( cudaMalloc((void**)&clocks_d, GRID*sizeof(int)) ); 

        //events creation 
        createAndStartEvent(&startEvent, &stopEvent);
        
        for (int i = 0; i < N_size/chunkSize; ++i) {  
            //random chunk
            randomArray(x+(i*chunkSize),chunkSize);

            //function calling kernel            
            cosKer(M_iter,chunkSize, x+(i*chunkSize), cosx+(i*chunkSize), x_d, clocks, clocks_d);
            
            //print results
            #ifndef MEASURES
                printCos(cosx+i*chunkSize, chunkSize);
            #endif                
        } 
        msTot = endEvent(&startEvent, &stopEvent);
    }
    else 
    {
        const int streamBytes = chunkSize*sizeof(float) ;

        //host pinned mem
        gpuErrchk( cudaMallocHost((void **)&x, N_size*sizeof(float)) ); //pinned x    
        gpuErrchk( cudaMallocHost((void **)&cosx, N_size*sizeof(float)) ); //pinned cosx
        gpuErrchk( cudaMallocHost((void **)&clocks, GRID*sizeof(int)) ); //pinned clocks            
        //device memory
        int strSize = nStreams*chunkSize;
        gpuErrchk( cudaMalloc((void**)&x_d, strSize*sizeof(float)) );
        gpuErrchk( cudaMalloc((void**)&clocks_d, GRID*nStreams*sizeof(int)) );  
        //stream array and events creation 
        cudaStream_t streams[nStreams];
        streamCreate(streams, nStreams);
        createAndStartEvent(&startEvent, &stopEvent);
  
        for (int i = 0; i < N_size/chunkSize; ++i) {  
            int k = i%nStreams;
            int strOffs = k*chunkSize;
            randomArray(x+i*chunkSize,chunkSize);
        
            cosKerStream( M_iter,chunkSize, x+(i*chunkSize), cosx+(i*chunkSize), x_d+strOffs, 
                            clocks, clocks_d+(k*GRID), streams[k], streamBytes, 0 );        
            #ifndef MEASURES
                printCos(cosx+i*chunkSize, chunkSize);
            #endif
            
        } 
        msTot = endEvent(&startEvent, &stopEvent);
        streamDestroy(streams,nStreams); 
    }
    end = std::chrono::system_clock::now();

    //print results
    #ifdef MEASURES
        millis = end-start;
        if (hyb)
        {
            label += "HYBR";
        }
        
        label += "STREAM";
        printMeasures(label, msTot, millis.count(), devId, nStreams, hyb, chunkSize);
    #endif
    
    //free Host and Device mem
    cudaFreeHost(x);
    cudaFreeHost(cosx);
    cudaFreeHost(clocks);
    cudaFree(x_d);
    cudaFree(clocks_d);


#elif DATAPAR

    start = std::chrono::system_clock::now();

    float *x, *cosx;
    int *clocks;
    float *x_d; 
    int *clocks_d;

    x = (float *) malloc(N_size*sizeof(float));
    cosx = (float *) malloc(N_size*sizeof(float));
    gpuErrchk( cudaMalloc((void**)&x_d, N_size*sizeof(float)) );

    randomArray(x,N_size);
    createAndStartEvent(&startEvent, &stopEvent);

    float msKer = optimalCosKer(M_iter, N_size, x, cosx, x_d, clocks, clocks_d); 

    msTot = endEvent(&startEvent, &stopEvent);
    end = std::chrono::system_clock::now();

#ifndef MEASURES
                printCos(cosx, N_size);
            #endif

    //print results
    #ifdef MEASURES
        millis = end-start;
        label += "DATAPAR";
        printMeasures(label, msKer, millis.count(), devId, nStreams, hyb, N_size);
    #endif
    
    //free Host and Device mem
    cudaFreeHost(x);
    cudaFreeHost(cosx);
    cudaFreeHost(clocks);
    cudaFree(x_d);
    cudaFree(clocks_d);












/*** STREAM ***/
#elif OLDSTREAM
    const int streamBytes = chunk*maxThreads*sizeof(float) ;

    start = std::chrono::system_clock::now();
    //host pinned memory
    float *x, *cosx;
    int *clocks;
    /* 
    gpuErrchk( cudaMallocHost((void **)&x, N_size*sizeof(float)) ); //pinned x    
    gpuErrchk( cudaMallocHost((void **)&cosx, N_size*sizeof(float)) ); //pinned cosx
    gpuErrchk( cudaMallocHost((void **)&clocks, GRID*sizeof(int)) ); //pinned clocks
    */
    float *x_d; 
    int *clocks_d;





    /* OPTIMAL OCCUPANCY ESTIMATION */

  /*   gpuErrchk( cudaMallocHost((void **)&x, N_size*sizeof(float)) ); //pinned x    
    gpuErrchk( cudaMallocHost((void **)&cosx, N_size*sizeof(float)) ); //pinned cosx
    gpuErrchk( cudaMallocHost((void **)&clocks, GRID*sizeof(int)) ); //pinned clocks
            
    
    int strSize = 3*maxThreads;
    gpuErrchk( cudaMalloc((void**)&x_d, strSize*sizeof(float)) );
    gpuErrchk( cudaMalloc((void**)&clocks_d, GRID*3*sizeof(int)) );  


    //stream array and events creation 
    cudaStream_t streams[nStreams];
    streamCreate(streams, nStreams);
    createAndStartEvent(&startEvent, &stopEvent);

    for (int i = 0; i < N_size/maxThreads; ++i) {  
        int k = i%3;
        int strOffs = k*maxThreads;
        randomArray(x+i*maxThreads,maxThreads);
           
        optimalCosKer(M_iter,maxThreads, x+(i*maxThreads), cosx+(i*maxThreads), x_d+strOffs, clocks, clocks_d+(k*GRID), streams[k], streamBytes, 0); 

        
        #ifndef MEASURES
            printCos(cosx+i*maxThreads, maxThreads);
        #endif
        
    } 
    msTot = endEvent(&startEvent, &stopEvent);
    streamDestroy(streams,nStreams); 

std::cout << "GRID SIZE: " <<GRID<<std::endl;*/
    
    if (nStreams==0)
    {
        
        #ifdef LOWPAR
            //gpuErrchk( cudaMallocHost((void **)&x, sizeof(float)) ); //pinned x    
            //gpuErrchk( cudaMallocHost((void **)&cosx, sizeof(float)) ); //pinned cosx
            //gpuErrchk( cudaMallocHost((void **)&clocks, sizeof(int)) ); //pinned clocks
    x = (float *) malloc(sizeof(float));
            cosx = (float *) malloc(sizeof(float));
            clocks = (int *) malloc(sizeof(int));


            //device memory
            
            gpuErrchk( cudaMalloc((void**)&x_d, sizeof(float)) );
            gpuErrchk( cudaMalloc((void**)&clocks_d, sizeof(float)) );   


            float val = 0.0f;
            for (int i = 0; i < N_size; ++i) {  
                //randomArray(x+i*chunk,chunk);
                x = LOW + (float) std::rand() * (HIGH-LOW) / RAND_MAX; 
                
                //cosKerStream(M_iter,chunk, x, cosx, x_d, clocks, clocks_d, (cudaStream_t) 0, streamBytes, 0);  

                      cosKer(M_iter,chunk, x, cosx, x_d, clocks, clocks_d, streamBytes);


                #ifndef MEASURES
                    printCos(cosx+i*chunk, chunk);
                #endif
            }   
                    msTot = endEvent(&startEvent, &stopEvent);

        #else

            //int strSize = nStreams*maxThreads;
           /*  gpuErrchk( cudaMallocHost((void **)&x, N_size*sizeof(float)) ); //pinned x    
            gpuErrchk( cudaMallocHost((void **)&cosx, N_size*sizeof(float)) ); //pinned cosx
            gpuErrchk( cudaMallocHost((void **)&clocks, GRID*sizeof(int)) ); //pinned clocks
*/

    x = (float *) malloc(N_size*sizeof(float));
            cosx = (float *) malloc(N_size*sizeof(float));
            clocks = (int *) malloc(GRID*sizeof(int));
            //device memory
            
            /*
            gpuErrchk( cudaMalloc((void**)&x_d, streamBytes*nStreams) );
            gpuErrchk( cudaMalloc((void**)&clocks_d, GRID*nStreams*sizeof(int)) );  

            */ 

            //int strSize = nStreams*maxThreads;
            gpuErrchk( cudaMalloc((void**)&x_d, maxThreads*sizeof(float)) );
            gpuErrchk( cudaMalloc((void**)&clocks_d, GRID*sizeof(int)) );  

            
               //stream array and events creation 
        createAndStartEvent(&startEvent, &stopEvent);
            
            for (int i = 0; i < N_size/maxThreads; ++i) {  
                //int k = i%nStreams;
                //int strOffs = k*maxThreads;
                randomArray(x+(i*maxThreads),maxThreads);
            
                //cosKerStream(M_iter,maxThreads, x+(i*maxThreads), cosx+(i*maxThreads), x_d, clocks, clocks_d, (cudaStream_t) 0, streamBytes, 0);        
                
                cosKer(M_iter,maxThreads, x+(i*maxThreads), cosx+(i*maxThreads), x_d, clocks, clocks_d, streamBytes);
                
                #ifndef MEASURES
                    printCos(cosx+i*maxThreads, maxThreads);
                #endif
                
            } 
                msTot = endEvent(&startEvent, &stopEvent);

        #endif
    }
    else 
    {
        /*
        gpuErrchk( cudaMallocHost((void **)&x, N_size*sizeof(float)) ); //pinned x    
        gpuErrchk( cudaMallocHost((void **)&cosx, N_size*sizeof(float)) ); //pinned cosx
        gpuErrchk( cudaMallocHost((void **)&clocks, GRID*sizeof(int)) ); //pinned clocks
         */

        //int strSize = nStreams*maxThreads;
        gpuErrchk( cudaMallocHost((void **)&x, N_size*sizeof(float)) ); //pinned x    
        gpuErrchk( cudaMallocHost((void **)&cosx, N_size*sizeof(float)) ); //pinned cosx
        gpuErrchk( cudaMallocHost((void **)&clocks, GRID*sizeof(int)) ); //pinned clocks
            
    //device memory
  
    /*
    gpuErrchk( cudaMalloc((void**)&x_d, streamBytes*nStreams) );
    gpuErrchk( cudaMalloc((void**)&clocks_d, GRID*nStreams*sizeof(int)) );  
    
     */ 

    int strSize = nStreams*maxThreads;
    gpuErrchk( cudaMalloc((void**)&x_d, strSize*sizeof(float)) );
    gpuErrchk( cudaMalloc((void**)&clocks_d, GRID*nStreams*sizeof(int)) );  


        //stream array and events creation 
        cudaStream_t streams[nStreams];
        streamCreate(streams, nStreams);
        createAndStartEvent(&startEvent, &stopEvent);

         /*for (int i = 0; i < K_exec; ++i) {  
           
            int k = i%nStreams;
            int strOffs = k*chunk;
            randomArray(x+i*chunk,chunk);
        
            cosKerStream(M_iter,chunk, x+(i*chunk), cosx+(i*chunk), x_d+strOffs, clocks, clocks_d+(k*GRID), streams[k], streamBytes, 0);        
            #ifndef MEASURES
                printCos(cosx+i*chunk, chunk);
            #endif
            
             */
        for (int i = 0; i < N_size/maxThreads; ++i) {  
            int k = i%nStreams;
            int strOffs = k*maxThreads;
            randomArray(x+i*maxThreads,maxThreads);
        
            cosKerStream(M_iter,maxThreads, x+(i*maxThreads), cosx+(i*maxThreads), x_d+strOffs, clocks, clocks_d+(k*GRID), streams[k], streamBytes, 0);        
            #ifndef MEASURES
                printCos(cosx+i*maxThreads, maxThreads);
            #endif
            
        } 
        msTot = endEvent(&startEvent, &stopEvent);
    streamDestroy(streams,nStreams); 
    }
    


      
       

    end = std::chrono::system_clock::now();

    //print results
    #ifdef MEASURES
        millis = end-start;
        label += "STREAM";
        printMeasures(label, msTot, millis.count(), devId, nStreams, hyb, chunkSize);
    #endif
    
    //free Host and Device space
    cudaFreeHost(x);
    cudaFreeHost(cosx);
    cudaFreeHost(clocks);
    cudaFree(x_d);
    cudaFree(clocks_d);

/*** FUTURE ***/
#elif FUTURE
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
    gpuErrchk( cudaMalloc((void **)&x_d, bytesSize*nStreams) );  // bytesSize
    gpuErrchk( cudaMalloc((void **)&clocks_d, GRID*nStreams*sizeof(int)) ); //GRID*sizeof(int)

    
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

/*** MANAGED ***/
#elif MANAGED
    const int streamBytes = chunk* sizeof(float);
    float *cosx, *x;
    int *clocks;
    int bytesClocks = GRID*sizeof(int);   
    
    start = std::chrono::system_clock::now();

    //stream array and events creation 
    cudaStream_t streams[nStreams];
    streamCreate(streams, nStreams);
    createAndStartEvent(&startEvent, &stopEvent);

    //unified memory
    cudaMallocManaged(&x, streamBytes*nStreams);
    cudaMallocManaged(&cosx, streamBytes*nStreams);
    cudaMallocManaged(&clocks, bytesClocks*nStreams);

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