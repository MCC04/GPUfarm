#include <iostream>
#include <math.h>
#include <stdlib.h>
 
#include <cstdlib>
#include <algorithm>
#include <ctime>
#include <vector>
#include <future>
#include <iterator>
#include <cosFutStr.h>

#define HIGH 500.0f
#define LOW -500.0f


void randomArray(float *x, int n){
    #ifndef MEASURES
            std::cout<<std::endl<< "X ARRAY: "<<std::endl;  
    #endif
    for(int i=0; i<n;i+=1){
        x[i] = LOW + (float) std::rand() * (HIGH-LOW) / RAND_MAX;   
        #ifndef MEASURES
            std::cout<< x[i] << ", ";  
        #endif
    }
}

/*********
**KERNELS*
**********/
__global__ void emptyKernel(){ return; }

__global__ void cosKernel(int M, int N, float *x_d, int *myclocks, int offset){    
    int idx = offset+blockIdx.x*blockDim.x + threadIdx.x; 
   
    clock_t start =clock();

    if(idx<N){
        for(int j=0; j<M; ++j)
        x_d[idx]=cosf(x_d[idx]);  
    }
    

    clock_t end=clock();

    if (threadIdx.x == 0) myclocks[blockIdx.x+(offset/blockDim.x)]=(int)(end-start);
    return ;
}

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
float emptyKer(){
    float ms=0;
    cudaEvent_t startEvent, stopEvent;
    checkCuda( cudaEventCreate(&startEvent) );
    checkCuda( cudaEventCreate(&stopEvent) );   

    checkCuda( cudaEventRecord(startEvent,0) );
    
    emptyKernel<<<GRID, BLOCK>>>();

    checkCuda( cudaEventRecord(stopEvent, 0) );
    checkCuda( cudaEventSynchronize(stopEvent) );
    checkCuda( cudaEventElapsedTime(&ms, startEvent, stopEvent) );

    return ms;    
}



/*void cosKer(my_struct *_xs, float *x_d, int *clocks_d, int chunkBytes,
            cudaEvent_t start, cudaEvent_t stop, cudaStream_t strm)
{    
    checkCuda( cudaEventRecord(start,0) );

    checkCuda(cudaMemcpyAsync(x_d, _xs->x_vect, chunkBytes, cudaMemcpyHostToDevice, strm));
    #ifdef LOWPAR
        //cosGridStride<<<GRID, BLOCK, 0, strm>>>(M_iter, N_size, x_d, clocks_d, 0);
        cosGridStride<<<GRID, BLOCK, 0, strm>>>(M_iter, chunk, x_d, clocks_d, 0);
    #else
        //cosKernel<<<GRID, BLOCK, 0, strm>>>(M_iter, N_size, x_d, clocks_d, 0);
        cosKernel<<<GRID, BLOCK, 0, strm>>>(M_iter, chunk, x_d, clocks_d, 0);
    #endif
    checkCuda(cudaMemcpyAsync( _xs->x_vect, x_d, chunkBytes, cudaMemcpyDeviceToHost, strm));
    checkCuda(cudaMemcpyAsync( _xs->clocks, clocks_d, GRID*sizeof(int), cudaMemcpyDeviceToHost, strm));

    checkCuda( cudaEventRecord(stop, 0) );
    checkCuda( cudaEventSynchronize(stop) );
    checkCuda( cudaEventElapsedTime(&_xs->eventTime, start, stop) );            
}*/


//FUTURE VECCHIO
/*void cosKer(std::vector<my_struct> &getDatas, int chunk, int bytesSize )
{
    std::vector<std::future<my_struct>> futures;
    int *clocks_d;
    float *x_d;    
    //float *x = new float[N_size];

    cudaEvent_t startEvent, stopEvent;
    checkCuda( cudaEventCreate(&startEvent) );
    checkCuda( cudaEventCreate(&stopEvent) );    

    checkCuda(cudaMalloc((void **)&x_d, bytesSize)); 
    checkCuda(cudaMalloc((void **)&clocks_d, GRID*sizeof(int)));


    checkCuda( cudaEventRecord(startEvent,0) );
    for(int i = 0; i < K_exec; ++i) {
        futures.push_back (std::async(std::launch::async,//std::launch::deferred,
            [&]() { 
                my_struct _xs;
                _xs.clocks=new int[GRID];
                _xs.x_vect=new float[chunk];
                randomArray(_xs.x_vect, chunk);
                //randomArray(&x[i*chunk], chunk);

                //checkCuda( cudaEventRecord(startEvent,0) );

                checkCuda(cudaMemcpy(x_d, _xs.x_vect, bytesSize, cudaMemcpyHostToDevice)); 
                //checkCuda(cudaMemcpy(x_d, &x[i*chunk], bytesSize, cudaMemcpyHostToDevice)); 

                #ifdef LOWPAR
                    cosGridStride<<<GRID, BLOCK>>>(M_iter, chunk, x_d, clocks_d, 0);
                #else
                    cosKernel<<<GRID, BLOCK>>>(M_iter, chunk, x_d,clocks_d, 0);
                #endif
                              
                checkCuda(cudaMemcpy( _xs.x_vect, x_d, bytesSize, cudaMemcpyDeviceToHost));
                checkCuda(cudaMemcpy(_xs.clocks, clocks_d, GRID*sizeof(int), cudaMemcpyDeviceToHost));

                /*checkCuda( cudaEventRecord(stopEvent, 0) );
                checkCuda( cudaEventSynchronize(stopEvent) );
                checkCuda( cudaEventElapsedTime(&_xs.eventTime, startEvent, stopEvent) );
                _xs.eventTime=0;

                return _xs;
            }));          
    }
    float ms=0.0f;
    checkCuda( cudaEventRecord(stopEvent, 0) );
    checkCuda( cudaEventSynchronize(stopEvent) );
    checkCuda( cudaEventElapsedTime(&ms, startEvent, stopEvent) );
    
    std::cout << "EVENT TIME FUTURE: "<< ms<<std::endl;
    
    for(auto &e : futures) 
        getDatas.push_back(e.get());
}*/




void printCos(float *cosx){    
    std::cout<<std::endl<<"COSX array : " <<std::endl;  
    //int chunk = N_size/K_exec;
    for(int j=0; j<N_size;j+=1) 
        std::cout << cosx[j] << ", ";    
    std::cout << std::endl;

      
}




//FUTURE CON STREAM
/*void cosKer(std::vector<my_struct> &getDatas, int chunk, int bytesSize )
{
    std::vector<std::future<my_struct>> futures;
    int *clocks_d;
    float *x_d;    
    float *x = new float[N_size];
    float *cosx = new float[N_size];
    float *clockss = new float[K_exec*GRID];

    cudaEvent_t startEvent, stopEvent;
    checkCuda( cudaEventCreate(&startEvent) );
    checkCuda( cudaEventCreate(&stopEvent) );    

    checkCuda( cudaMalloc((void **)&x_d, N_size*sizeof(float)) ); 
    checkCuda( cudaMalloc((void **)&clocks_d, GRID*K_exec*sizeof(int)) );


    checkCuda( cudaEventRecord(startEvent,0) );

    randomArray(x, N_size);
    //cudaStream_t str1;
    //checkCuda( cudaStreamCreate(&str1) );
    cudaStream_t *stream=streamCreate(3);
    for(int i = 0; i < K_exec; ++i) {
        
     
        futures.push_back (
         //auto myFut=   
         std::async(std::launch::async,//std::launch::deferred,//
            [x,x_d,clocks_d,chunk,stream](int i ) { 
                my_struct _xs;
                _xs.clocks=new int[GRID];
                _xs.x_vect=new float[chunk];
                int k = i%3;
                //randomArray(_xs.x_vect, chunk);
                //randomArray(&x[i*chunk], chunk);

                //checkCuda( cudaEventRecord(startEvent,0) );

                //checkCuda( cudaMemcpy(&x_d[i*chunk], &x[i*chunk], bytesSize, cudaMemcpyHostToDevice) ); 
                std::cout <<i<<" - going to memcpy x in H2D..."<<std::endl;
                checkCuda( cudaMemcpyAsync(&x_d[i*chunk], &x[i*chunk], chunk*sizeof(float), cudaMemcpyHostToDevice, stream[k]) );          
                std::cout << i<<"- done memcpy x in H2D!"<<std::endl;
                ////checkCuda(cudaMemcpy(x_d, &x[i*chunk], bytesSize, cudaMemcpyHostToDevice)); 

                #ifdef LOWPAR
                    cosGridStride<<<GRID, BLOCK,0,stream[k]>>>(M_iter, chunk, &x_d[i*chunk], &clocks_d[i*chunk], 0);
                #else
                    std::cout << i<<"- kernel launch..."<<std::endl;

                    cosKernel<<<GRID, BLOCK,0,stream[k]>>>(M_iter, chunk, &x_d[i*chunk],&clocks_d[i*chunk], 0);
                    cudaDeviceSynchronize();
                    std::cout << i<<"- kernel end!"<<std::endl;

                #endif
                              
                //checkCuda( cudaMemcpy( _xs.x_vect, &x_d[i*chunk], chunk*sizeof(float), cudaMemcpyDeviceToHost) );
                //checkCuda( cudaMemcpy(_xs.clocks, &clocks_d[i*GRID], GRID*sizeof(int), cudaMemcpyDeviceToHost) );
                std::cout << i<<"- going to memcpy in D2H..."<<std::endl;

                checkCuda( cudaMemcpyAsync(_xs.x_vect, &x_d[i*chunk], chunk*sizeof(float), cudaMemcpyDeviceToHost, stream[k]) );
                checkCuda( cudaMemcpyAsync(_xs.clocks, &clocks_d[i*GRID], GRID*sizeof(int), cudaMemcpyDeviceToHost, stream[k]) );
                std::cout << i<<"- done memcpy H2D..."<<std::endl;

                //checkCuda( cudaEventRecord(stopEvent, 0) );
                //checkCuda( cudaEventSynchronize(stopEvent) );
                //checkCuda( cudaEventElapsedTime(&_xs.eventTime, startEvent, stopEvent) );
                _xs.eventTime=0;

                return _xs;
            },i));  

            //auto obj=myFut.get(); 

        
    }
    float ms=0.0f;

    
    for(auto &e : futures) 
            getDatas.push_back(e.get()); 
    
       //printCos(cosx);
        
    checkCuda( cudaEventRecord(stopEvent, 0) );
    checkCuda( cudaEventSynchronize(stopEvent) );
    checkCuda( cudaEventElapsedTime(&ms, startEvent, stopEvent) );

    std::cout << "EVENT TIME FUTURE: "<< ms<<std::endl;
streamDestroy(stream,3);
}*/



//NB: launch deferred funziona sempre (sia memcpy, sia memcpyasync) perché non crea overlapping
//facendo la lambda quando chiamo get, non so esattamente perché, ma
//non ho più qualcosa che somigli a chiamate asincrone, ma diventa tutto
//seriale. Esempio: h2d, ker0, d2h -- h2d, ker1, d2h ....



//Le memcpy danno problemi perché quando uso quelle con async,
//partono tutte le memcpy h2d e dopo tutti i kernel e le d2h.
//questo probabilmente collegato al fatto che sono sincrone e
//quindi nel frattempo che viene aspettata la copia parte la memcpy
//successiva. Però poi quando chiamo i kernel tutti insieme succede un casino
//col mapping della memoria, hp eccezioni di accesso illegale alla memoria.
//Questo probabilmente è dovuto al fatto che es sono state fatte molte 
//memcpy, arriva il kernelO e la sua memoria è stata "manomessa" da 
//altre memcopy ---> però c'è da dire che in teoria userei porzioni diverse
//dell'array x_d allocato in device.
//magari sbaglio qualcosa nelle memcpy?
//fatto sta che non è un'ottimo risultato in quanto a overlapping in ogni caso
//per questo credo sia meglio fare con memcpyasync

void cosKer(std::vector<my_struct> &getDatas, int chunk, int bytesSize )
{
    std::vector<std::future<my_struct>> futures;
    int *clocks_d;
    float *x_d; 

    float *x = new float[N_size];
    //checkCuda( cudaMallocHost((void **)&x, N_size*sizeof(float)) ); //pinned x
    float *cosx = new float[N_size];
    //checkCuda( cudaMallocHost((void **)&cosx, N_size*sizeof(float)) ); //pinned x
    float *clockss = new float[K_exec*GRID];
    //checkCuda( cudaMallocHost((void **)&clockss, K_exec*GRID*sizeof(float)) ); //pinned x


    cudaEvent_t startEvent, stopEvent;
    checkCuda( cudaEventCreate(&startEvent) );
    checkCuda( cudaEventCreate(&stopEvent) );    

    checkCuda( cudaMalloc((void **)&x_d, N_size*sizeof(float)) ); 
    checkCuda( cudaMalloc((void **)&clocks_d, GRID*K_exec*sizeof(int)) );


    checkCuda( cudaEventRecord(startEvent,0) );

    randomArray(x, N_size);
    //cudaStream_t str1;
    //checkCuda( cudaStreamCreate(&str1) );
    cudaStream_t *stream=streamCreate(3);
    for(int i = 0; i < K_exec; ++i) {
        
     
        futures.push_back (
         //auto myFut=   
         std::async(std::launch::deferred,//std::launch::async,//
            //[x,x_d,clocks_d,chunk](int i ) { 
             [x,x_d,clocks_d,chunk,stream](int i ) { 

                my_struct _xs;
                _xs.clocks=new int[GRID];
                _xs.x_vect=new float[chunk];
                int k = i%3;
                //randomArray(_xs.x_vect, chunk);
                //randomArray(&x[i*chunk], chunk);

                //checkCuda( cudaEventRecord(startEvent,0) );
                std::cout <<i<<" - going to memcpy x in H2D..."<<std::endl;
                //checkCuda( cudaMemcpy(&x_d[i*chunk], &x[i*chunk], chunk*sizeof(float), cudaMemcpyHostToDevice) ); 
                
               checkCuda( cudaMemcpyAsync(&x_d[i*chunk], &x[i*chunk], chunk*sizeof(float), cudaMemcpyHostToDevice, stream[k]) );          
                std::cout << i<<"- done memcpy x in H2D!"<<std::endl;
                ////checkCuda(cudaMemcpy(x_d, &x[i*chunk], bytesSize, cudaMemcpyHostToDevice)); 

               // #ifdef LOWPAR
                    
                     std::cout << i<<"- kernel launch..."<<std::endl;
                     cosGridStride<<<GRID, BLOCK,0,stream[k]>>>(M_iter, chunk, &x_d[i*chunk], &clocks_d[i*chunk], 0);
                     //cosGridStride<<<GRID, BLOCK>>>(M_iter, chunk, &x_d[i*chunk], &clocks_d[i*chunk], 0);
               // #else
                   
                 //   cosKernel<<<GRID, BLOCK>>>(M_iter, chunk, &x_d[i*chunk],&clocks_d[i*chunk], 0);
                    //cosKernel<<<GRID, BLOCK,0,stream[k]>>>(M_iter, chunk, &x_d[i*chunk],&clocks_d[i*chunk], 0);
                    //cudaDeviceSynchronize();
                    std::cout << i<<"- kernel end!"<<std::endl;

              //  #endif
                              
                
                std::cout << i<<"- going to memcpy in D2H..."<<std::endl;
                //checkCuda( cudaMemcpy( _xs.x_vect, &x_d[i*chunk], chunk*sizeof(float), cudaMemcpyDeviceToHost) );
                //checkCuda( cudaMemcpy(_xs.clocks, &clocks_d[i*GRID], GRID*sizeof(int), cudaMemcpyDeviceToHost) );
                checkCuda( cudaMemcpyAsync(_xs.x_vect, &x_d[i*chunk], chunk*sizeof(float), cudaMemcpyDeviceToHost, stream[k]) );
                checkCuda( cudaMemcpyAsync(_xs.clocks, &clocks_d[i*GRID], GRID*sizeof(int), cudaMemcpyDeviceToHost, stream[k]) );
                std::cout << i<<"- done memcpy H2D..."<<std::endl;

                /*checkCuda( cudaEventRecord(stopEvent, 0) );
                checkCuda( cudaEventSynchronize(stopEvent) );
                checkCuda( cudaEventElapsedTime(&_xs.eventTime, startEvent, stopEvent) );*/
                _xs.eventTime=0;

                return _xs;
            },i));  

            //auto obj=myFut.get(); 

        
    }
    float ms=0.0f;

    
    for(auto &e : futures) 
            getDatas.push_back(e.get()); 
    
       //printCos(cosx);
        
    checkCuda( cudaEventRecord(stopEvent, 0) );
    checkCuda( cudaEventSynchronize(stopEvent) );
    checkCuda( cudaEventElapsedTime(&ms, startEvent, stopEvent) );

    std::cout << "EVENT TIME FUTURE: "<< ms<<std::endl;
    streamDestroy(stream,3);

        cudaFreeHost(x);
        cudaFreeHost(cosx);
        cudaFreeHost(clockss);

    cudaFree(x_d);
    cudaFree(clocks_d);
}




















void cosKerStream(
    int m, int chunk,
    float *x, int *clocks, 
    int offset, cudaStream_t strm)
{
       /* #ifdef LOWPAR
            cosGridStride<<<GRID, BLOCK, offset, strm>>>(m, n, x, clocks, offset);
        #else
            cosKernel<<<GRID, BLOCK, offset, strm>>>(m, n, x, clocks, offset);
        #endif*/
       // #ifdef LOWPAR
            cosGridStride<<<GRID, BLOCK, offset, strm>>>(m, chunk, x, clocks, offset);
       // #else
         //   cosKernel<<<GRID, BLOCK, offset, strm>>>(m, chunk, x, clocks, offset);
        //#endif
}

float  cosKerStream(
    cudaEvent_t start, cudaEvent_t stop,
    int m, int chunk,//int n,
    float *x, float *cosx,  int *clocks, 
    int offset, cudaStream_t strm)
{
    float ms;  
    //randomArray(x, n);
    //memcpy(cosx,x,N_size);
    randomArray(x,chunk);
    memcpy(cosx,x,chunk);
    
    checkCuda( cudaEventRecord(start,0) );

    //#ifdef STRIDE
    #ifdef LOWPAR
        //cosGridStride<<<GRID, BLOCK, offset, strm>>>(m, n, cosx, clocks, offset);
        cosGridStride<<<GRID, BLOCK, offset, strm>>>(m, chunk, cosx, clocks, offset);
    #else
        //cosKernel<<<GRID, BLOCK, offset, strm>>>(m, n, cosx, clocks, offset);
        cosKernel<<<GRID, BLOCK, offset, strm>>>(m, chunk, cosx, clocks, offset);
    #endif

    checkCuda( cudaEventRecord(stop, 0) );
    checkCuda( cudaEventSynchronize(stop) );
    checkCuda( cudaEventElapsedTime(&ms, start, stop) );
     
    return ms;
}
