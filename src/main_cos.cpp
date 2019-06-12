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
        //std::cout << N_size<<"," << K_exec<< "," << M_iter<< "," <<GRID<< "," <<BLOCK << std::endl;
        std::cout<< K_exec <<","<< N_size <<","<< M_iter <<","<< BLOCK <<","<< GRID;
    #endif     
}

void printResults(float ms){
    float rb_wb=bytesSize*2 + GRID*sizeof(float); 
    std::cout <<"*"<< ms<< ","<< (rb_wb/ms/1e6)<<std::endl; 
}

void printTotalTimes(float eventsTime,  float hostTime ){
    #ifdef MEASURES
        //std::cout<<std::endl<<"$"<< eventsTime<<","<<hostTime<<std::endl;
        std::cout<< eventsTime <<","<< hostTime;// <<std::endl;

    #else
        std::cout<<std::endl<<"----Total Device Events measures: "<< eventsTime<<"ms"<<std::endl;
        std::cout<<std::endl<<"----Total Host measures: "<< hostTime <<"ms"<<std::endl;
    #endif
}

void printAll(float *cosx, int size, int *clocks, float ms){    
    std::cout<<std::endl<<"COSX array : " <<std::endl;  
    //int chunk = N_size/K_exec;
    //for(int j=0; j<chunk;j+=1) 
    for(int j=0; j<size;j+=1) 

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

int main(int argc, char **argv){  
    std::srand(static_cast <unsigned> (time(NULL)));

    int gpu_clk=1;
    float clockSum=0.0, clockAvg=0.0;
    float msSum=0.0, rb_wb=0.0;     
    float ms=0;
    std::string label;
    std::chrono::system_clock::time_point start,end;
    std::chrono::duration<double, std::milli> millis;  

    //args
    int devId = atoi(argv[1]); 
    BLOCK = atoi(argv[2]);
    K_exec = atoi(argv[3]);
    M_iter = atoi(argv[4]);
    N_size = atoi(argv[5]);

    int chunk = N_size/K_exec;
    bytesSize = chunk*sizeof(float); //bytesSize = N_size*sizeof(float); 

    //grid setting
    #ifdef LOWPAR
        GRID=1;
        label = "LOW";
    #else
        label = "";
        GRID = ceil(chunk/BLOCK); //then make test on non divisible factors 
    #endif


    #ifdef EMPTY
        std::cout <<"*";
        for (int i = 0; i < K_exec; ++i) {  
            float ms=emptyKer();
            std::cout <<ms<< ",";     
        }
        std::cout <<std::endl; 
        return 0;
    #endif


    //device id setting
    checkCuda(cudaDeviceGetAttribute(&gpu_clk, cudaDevAttrClockRate, devId));    
    checkCuda( cudaSetDevice(devId) );
    checkCuda( cudaGetDeviceProperties(&prop, devId));     

/*** FUTURE ***/
#ifdef FUTURE
    std::vector<double> bandW;
    std::vector<my_struct> getDatas;   

    #ifndef MEASURES
        printInfos(); 
    #endif

    //chrono start
    start=std::chrono::system_clock::now();

    //kernels launcher
    ms = cosKer(getDatas,chunk, bytesSize);

    //data gathering
    #ifndef MEASURES
    for(auto item : getDatas){  
        
            printAll(item.x_vect, chunk, item.clocks, item.eventTime);
            float rb_wb=bytesSize*2 + GRID*sizeof(float); 
            bandW.push_back(rb_wb/item.eventTime/1e6);
        
       // ms+=item.eventTime;
    } 
    #endif 

    //chrono end
    end=std::chrono::system_clock::now();

    //print results
    #ifdef MEASURES
        millis = end-start;
        label += "FUTURE";
        std::cout<< label << ","<< ms <<","<< millis.count() <<","             //outputs
                            << M_iter <<","<< N_size <<"," << K_exec <<","      //inputs
                            << devId <<","<< BLOCK <<","<< GRID << std::endl;   //GPU infos
    #endif

/*** STREAM ***/
#elif STREAM
    const int nStream= 3;
    const int streamBytes = chunk*sizeof(float) ;
   
    //chrono start
    start=std::chrono::system_clock::now();

    //allocate host pinned memory
    float *x;         
    float *cosx;
    int *clocks;
    checkCuda( cudaMallocHost((void **)&x, N_size*sizeof(float)) ); //pinned x    
    checkCuda( cudaMallocHost((void **)&cosx, N_size*sizeof(float)) ); //pinned cosx
    checkCuda( cudaMallocHost((void **)&clocks, GRID*sizeof(float)) ); //pinned clocks
    //allocate device memory
    float *x_d; 
    int *clocks_d;
    checkCuda( cudaMalloc((void**)&x_d, streamBytes) );
    checkCuda( cudaMalloc((void**)&clocks_d, GRID*sizeof(int)) );
   
    //stream array create
    cudaStream_t *stream=streamCreate(nStream);
    //events creation and start
    cudaEvent_t startEvent, stopEvent;
    checkCuda( cudaEventCreate(&startEvent) );
    checkCuda( cudaEventCreate(&stopEvent) );
    checkCuda( cudaEventRecord(startEvent,0) );

    for (int i = 0; i < K_exec; ++i) {  
        int k = i%nStream;
        randomArray(&x[i*chunk],chunk);
        
        checkCuda( cudaMemcpyAsync(x_d, &x[i*chunk], streamBytes, cudaMemcpyHostToDevice, stream[k]) ); 
        //cos kernel call, move memcpy there then
        cosKerStream(M_iter,chunk, x_d, clocks_d, stream[k],0);
        
        checkCuda( cudaMemcpyAsync( &cosx[i*chunk], x_d, streamBytes, cudaMemcpyDeviceToHost, stream[k]) );
        checkCuda( cudaMemcpyAsync( clocks, clocks_d, GRID*sizeof(int), cudaMemcpyDeviceToHost, stream[k]) );
    }    

    //events stop
    checkCuda( cudaEventRecord(stopEvent, 0) );
    checkCuda( cudaEventSynchronize(stopEvent) );
    checkCuda( cudaEventElapsedTime(&ms, startEvent, stopEvent) );
    
    //stream array destroy
    streamDestroy(stream,nStream);    

    //chrono end
    end=std::chrono::system_clock::now();

    //print results
    #ifdef MEASURES
        millis = end-start;
        label += "STREAM";
        std::cout<< label <<","<< ms <<","<< millis.count() <<","             //outputs
                            << M_iter <<","<< N_size <<"," << K_exec <<","      //inputs
                            << devId <<","<< BLOCK <<","<< GRID << std::endl;   //GPU infos
    #else    
        printInfos(); 
        printAll(cosx, N_size, clocks, ms);
    #endif
    
    //free Host and Device space
    cudaFreeHost(x);
    cudaFreeHost(cosx);
    cudaFreeHost(clocks);
    cudaFree(x_d);
    cudaFree(clocks_d);



/*** MANAGED ***/
#elif MANAGED
    int nStream= 3;
    //const int streamSize = N_size ;
    //const int streamBytes = streamSize* sizeof(float) ;
    const int streamBytes = chunk* sizeof(float) ;

    float ms=0.0;
    float msTot=0.0;
    #ifndef LOWPAR
        //GRID=streamSize/BLOCK;
        GRID = chunk/BLOCK;

    #endif
    int *clocks;
    clocks=new int[GRID]; 
    //float *cosx=new float[N_size];
    //int bytesX = N_size*sizeof(float);
    float *cosx=new float[chunk];
    int bytesX = chunk*sizeof(float);
    int bytesClocks = GRID*sizeof(int);
   
    std::cout<<std::endl<<"MANAGED,";
    printInfos();
       
    start=std::chrono::system_clock::now();
    
    cudaEvent_t startEvent, stopEvent;  
    checkCuda( cudaEventCreate(&startEvent) );
    checkCuda( cudaEventCremsSumate(&stopEvent) );  

    cudaEvent_t startTot, stopTot;  
    checkCuda( cudaEventCreate(&startTot) );
    checkCuda( cudaEventCreate(&stopTot) ); 

    cudaStream_t *stream=streamCreate(nStream);

    checkCuda( cudaEventRecord(startTot,0) );
    cudaMallocManaged(&x, bytesX);
    cudaMallocManaged(&cosx, bytesX);
    cudaMallocManaged(&clocks, bytesClocks);

    checkCuda( cudaEventRecord(stopTot, 0) );
    checkCuda( cudaEventSynchronize(stopTot) );
    checkCuda( cudaEventElapsedTime(&msSum, startTot, stopTot) );


    for (int i = 0; i < K_exec; ++i) {   
        int k = i%nStream;
        /*ms=cosKerStream(startEvent,stopEvent,M_iter, N_size,
                        x, cosx, clocks, 0, stream[k]);*/
        ms=cosKerStream(startEvent,stopEvent,M_iter, chunk,
                        x, cosx, clocks, 0, stream[k]);

        #ifndef MEASURES
            printAll(cosx, clocks, ms);
        //#else
            //printResults(ms);
        #endif

        msTot+=ms;
    }

  
    msSum+=msTot;

    streamDestroy(stream,nStream);
    end=std::chrono::system_clock::now();

#endif
    #ifndef MEASURES
    printTotalTimes(ms, (end-start).count());
    #endif

    cudaDeviceReset();
    return 0;
}

