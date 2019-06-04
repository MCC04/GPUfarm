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

void printAll(float *cosx, int *clocks, float ms){    
    std::cout<<std::endl<<"COSX array : " <<std::endl;  
    int chunk = N_size/K_exec;
    for(int j=0; j<chunk;j+=1) 
    //for(int j=0; j<N_size;j+=1) 

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
    std::chrono::system_clock::time_point start,end;

    int devId = atoi(argv[1]);
    #ifdef LOWPAR
        BLOCK=64;//BLOCK=8;
        GRID=1;
    #else
        BLOCK = atoi(argv[2]);
    #endif
    K_exec = atoi(argv[3]);
    M_iter = atoi(argv[4]);
    N_size = atoi(argv[5]);


    #ifdef EMPTY
        std::cout <<"*";
        for (int i = 0; i < K_exec; ++i) {  
            float ms=emptyKer();
            std::cout <<ms<< ",";     
        }
        std::cout <<std::endl; 

        return 0;
    #endif

    //bytesSize = N_size*sizeof(float); 
    int chunk = N_size/K_exec;
    bytesSize = chunk*sizeof(float); 

    //float *x=new float [N_size]; 

     
    checkCuda(cudaDeviceGetAttribute(&gpu_clk, cudaDevAttrClockRate, devId));    
    checkCuda( cudaSetDevice(devId) );
    checkCuda( cudaGetDeviceProperties(&prop, devId));     

#ifdef FUTURE
    std::cout<<std::endl<<"FUTURE,"<<devId;
    #ifndef LOWPAR
        //GRID=N_size/BLOCK; 
        GRID = chunk/BLOCK; 
    #endif
    
    printInfos();
    std::vector<my_struct> getDatas;   
    start=std::chrono::system_clock::now();

    cosKer(getDatas,chunk, bytesSize);

    std::vector<double> bandW;

    /*#ifdef MEASURES
        std::cout << std::endl << "*";
    #endif*/
    for(auto item : getDatas){  
        #ifndef MEASURES
            printAll(item.x_vect, item.clocks, item.eventTime);
        #else
            //std::cout<< item.eventTime <<",";
            float rb_wb=bytesSize*2 + GRID*sizeof(float); 
            bandW.push_back(rb_wb/item.eventTime/1e6);
        #endif 
        msSum+=item.eventTime;
    } 
    /*#ifdef MEASURES
    std::cout <<std::endl<<"@";
    for(auto b : bandW){ 
        std::cout<< b <<",";
    }
    #endif*/
    end=std::chrono::system_clock::now();

    //cudaFreeHost(x);
#elif STREAM
    int nStream= 3;
    int *clocks_d,*clocks;
    float *cosx;
    //float *cosx=new float[N_size];
    checkCuda( cudaMallocHost((void **)&cosx, N_size*sizeof(float)) ); //pinned cosx

    //float *cosx=new float[chunk];
    //const int streamSize = N_size;
    //const int streamBytes = streamSize* sizeof(float) ;
    const int streamBytes = chunk*sizeof(float) ;
    #ifndef LOWPAR
        //GRID=streamSize/BLOCK; 
        GRID=ceil(chunk/BLOCK); 

    #endif
    //clocks=new int[GRID];
        float *x;     

    checkCuda( cudaMallocHost((void **)&x, N_size*sizeof(float)) ); //pinned x
    checkCuda( cudaMallocHost((void **)&clocks, GRID*sizeof(float)) ); //pinned clocks
 

    std::cout<<std::endl<<"STREAM,";
    printInfos();    

    start=std::chrono::system_clock::now();

    cudaEvent_t startEvent, stopEvent;
    checkCuda( cudaEventCreate(&startEvent) );
    checkCuda( cudaEventCreate(&stopEvent) );

    float *x_d;
    float ms=0;
    checkCuda( cudaMalloc((void**)&x_d, streamBytes) );
    checkCuda( cudaMalloc((void**)&clocks_d, GRID*sizeof(int)) );
   
    cudaStream_t *stream=streamCreate(nStream);

    checkCuda( cudaEventRecord(startEvent,0) );

    for (int i = 0; i < K_exec; ++i) {  
        int k = i%nStream;
        //ms=0;   
        //randomArray(x,N_size);
        randomArray(&x[i*chunk],chunk);

       //// checkCuda( cudaEventRecord(startEvent,0) );
        
        checkCuda( cudaMemcpyAsync(x_d, &x[i*chunk], streamBytes, cudaMemcpyHostToDevice, stream[k]) );          
        //cosKerStream(M_iter,N_size, x_d, clocks_d, 0, stream[k]);
        cosKerStream(M_iter,chunk, x_d, clocks_d, 0, stream[k]);
        
        checkCuda( cudaMemcpyAsync( &cosx[i*chunk], x_d, streamBytes, cudaMemcpyDeviceToHost, stream[k]) );
        checkCuda( cudaMemcpyAsync( clocks, clocks_d, GRID*sizeof(int), cudaMemcpyDeviceToHost, stream[k]) );

       /// checkCuda( cudaEventRecord(stopEvent, 0) );
       /// checkCuda( cudaEventSynchronize(stopEvent) );
       /// checkCuda( cudaEventElapsedTime(&ms, startEvent, stopEvent) );
   
        #ifndef MEASURES
           // printAll(&cosx[i*chunk], clocks, ms);
        //#else
          //  printResults(ms);
        #endif   

       // msSum+=ms;
    }    
    //cudaDeviceSynchronize();

    checkCuda( cudaEventRecord(stopEvent, 0) );
    checkCuda( cudaEventSynchronize(stopEvent) );
    checkCuda( cudaEventElapsedTime(&ms, startEvent, stopEvent) );

    printAll(cosx, clocks, ms);

    streamDestroy(stream,nStream);    
    //delete [] cosx;
    //delete [] clocks;
    cudaFreeHost(x);

    cudaFreeHost(cosx);
    cudaFreeHost(clocks);

    cudaFree(x_d);
    cudaFree(clocks_d);

    end=std::chrono::system_clock::now();

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
    checkCuda( cudaEventCreate(&stopEvent) );  

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
    printTotalTimes(msSum,  (end-start).count() );

    #ifndef MANAGED
        //delete [] x;
    #endif
    #ifdef STREAM 
        cudaFree(x_d);
        cudaFree(clocks_d);
    //#elif STREAMMANAGED
      //  cudaFree(x);
       // cudaFree(clocks);
    #endif

    return 0;
}

