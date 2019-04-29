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
#include <imageMatrix.h>

cudaDeviceProp prop;
int BLOCK=0;
int GRIDx=0;
int GRIDy=0;

int K_exec=0;
int M_iter=0;
int N_size=0;
int bytesSize;

void printInfos(){
    #if !defined(MEASURES) 
        std::cout<<"Device : "<< prop.name <<std::endl;
        std::cout<<"multiproc num : "<< prop.multiProcessorCount <<std::endl;
        std::cout<<"warp size : "<< prop.warpSize <<std::endl;
            
        std::cout << "Items number \t Host iterations \t Kernel iterations " << std::endl;
        std::cout << N_size<<" \t \t \t " << K_exec<< " \t \t \t " << M_iter << std::endl;
    #else
        std::cout<<BLOCK<<","<<GRIDx<<","<<GRIDy<<","<< N_size<<"," << K_exec<< "," << M_iter;
    #endif     
}

void printResults(float ms){
    float rb_wb=bytesSize*2 + GRIDx*sizeof(float); 
    std::cout <<"*"<< ms<< ","<< (rb_wb/ms/1e6)<<std::endl; 
}

void printTotalTimes(float eventsTime,  float hostTime){
    #ifdef MEASURES
        std::cout<<std::endl<<"$"<< eventsTime<<","<<hostTime<<std::endl;
    #else
        std::cout<<std::endl<<"----Total Device Events measures: "<< eventsTime<<"ms"<<std::endl;
        std::cout<<std::endl<<"----Total Host measures: "<< hostTime <<"ms"<<std::endl;
    #endif
}



void printMatrix(float *Cmat,int m, int n, float ms){
    float rb_wb=bytesSize*2 + GRIDx*sizeof(float); 
   #ifndef MEASURES
        std::cout<<"result MATRIX : " <<std::endl;  
        for (int i = 0; i < m; ++i)
        {
            for (int j = 0; j < n; ++j){
                float val=getMatrixVal<float>(Cmat,i,j,n);
                std::cout<<val << " ";
            }
                
            std::cout<<std::endl;
        }      

        std::cout<< std::endl <<"-------------------------"<< std::endl; 
        std::cout << "Event time(ms) "<< ms<<std::endl; 
        std::cout<<std::endl<<"Effective Bandwidth: "<< (rb_wb/ms/1e6)<<"GB/s"<<std::endl;        
    #else                
        std::cout <<"*"<< ms<< ","<< (rb_wb/ms/1e6)<<std::endl; 
    #endif
}


int main(int argc, char **argv){
    std::srand(static_cast <unsigned> (time(NULL)));

    int gpu_clk=1;
    float clockSum=0.0, clockAvg=0.0;
    float msSum=0.0, rb_wb=0.0; 
    std::chrono::system_clock::time_point start,end;

    int devId = atoi(argv[1]);
     #ifndef LOWPAR
        BLOCK = atoi(argv[2]);
    #endif
    int Nstr = atoi(argv[3]);

    bytesSize = N_size*sizeof(float); 
     
    checkCuda(cudaDeviceGetAttribute(&gpu_clk, cudaDevAttrClockRate, devId));    
    checkCuda( cudaSetDevice(devId) );
    checkCuda( cudaGetDeviceProperties(&prop, devId));     

#ifdef MATMUL
    
    M_iter = atoi(argv[4]);
    K_exec = atoi(argv[5]);
    N_size = atoi(argv[6]);
    int matN = atoi(argv[7]);

    const int streamSize = N_size ;
    const int streamBytes = streamSize* sizeof(float);
    float ms=0.0;

    int bytesA=M_iter*K_exec*sizeof(float);
    int bytesB=K_exec*N_size*sizeof(float);
    int bytesC=M_iter*N_size*sizeof(float);
    float  *A=(float*)calloc(matN, bytesA);//new float[M_iter*K_exec];
    float *B=(float*)calloc(matN, bytesB);//new float[K_exec*N_size] ;
    float * C=(float*)calloc(matN, bytesC);//new float[M_iter*N_size];

    cudaEvent_t startEvent, stopEvent;
    checkCuda( cudaEventCreate(&startEvent) );
    checkCuda( cudaEventCreate(&stopEvent) );
 
    #ifdef LOWPAR
        BLOCK=4;
        GRIDx= 1;
        GRIDy= 1;
    #else
        GRIDx= (M_iter/BLOCK)+56;
        GRIDy= (N_size/BLOCK)+57;
    #endif

    std::cout<<std::endl<<std::endl<<"#MATMUL,";
    printInfos();
    std::cout<<","<<Nstr<<","<<matN<<std::endl;
  
    start=std::chrono::system_clock::now();
    
    checkCuda( cudaMallocManaged(&A, bytesA*matN) );
    checkCuda( cudaMallocManaged(&B, bytesB*matN) );
    checkCuda( cudaMallocManaged(&C, bytesC*matN) );

    cudaStream_t *stream=streamCreate(Nstr);

    for (int j = 0; j < Nstr; ++j) {  
        for (int i = 0; i < matN; ++i) {  
            ms=matMulKer(&A[i*M_iter*K_exec], &B[i*K_exec*N_size], &C[i*M_iter*N_size], 
                        M_iter, K_exec, N_size, stream[j], startEvent, stopEvent);

            #if !defined(MEASURES)
                printMatrix(&C[i*M_iter*N_size], M_iter, N_size, ms);
            #else
                printResults(ms);
            #endif

            msSum+=ms;
        }   
    }
    streamDestroy(stream,Nstr);
    end=std::chrono::system_clock::now();

#elif SMALLMATMUL    
    M_iter = atoi(argv[4]);
    K_exec = atoi(argv[5]);
    N_size = atoi(argv[6]);
    int matN = atoi(argv[7]);

    const int streamSize = N_size ;
    const int streamBytes = streamSize* sizeof(float);
    float ms=0.0;

    int bytesA=M_iter*K_exec*sizeof(float);
    int bytesB=K_exec*N_size*sizeof(float);
    int bytesC=M_iter*N_size*sizeof(float);
    float *Ad=(float*)calloc(1,bytesA);//new float[M_iter*K_exec];
    float *Bd=(float*)calloc(1,bytesB);//new float[K_exec*N_size] ;
    float *Cd=(float*)calloc(1,bytesC);//new float[M_iter*N_size];
    float *C=(float*)calloc(1,bytesC);//new float[M_iter*N_size];

    cudaEvent_t startEvent, stopEvent;
    checkCuda( cudaEventCreate(&startEvent) );
    checkCuda( cudaEventCreate(&stopEvent) );

    #ifdef LOWPAR
        BLOCK=4;
        GRIDx= 1;
        GRIDy= 1;
    #else
        GRIDx= (M_iter/BLOCK)+56;
        GRIDy= (N_size/BLOCK)+57;
    #endif

    std::cout<<std::endl<<std::endl<<"#MATMUL,";
    printInfos();
    std::cout<<","<<Nstr<<","<<matN<<std::endl;
  
    start=std::chrono::system_clock::now();
    
    checkCuda( cudaMalloc(&Ad, bytesA) );
    checkCuda( cudaMalloc(&Bd, bytesB) );
    checkCuda( cudaMalloc(&Cd, bytesC) );

    cudaStream_t *stream=streamCreate(Nstr);

    for (int j = 0; j < Nstr; ++j) {  
        for (int i = 0; i < matN; ++i) {  

            ms=smallMatMulKer(Ad, Bd, Cd, C,
                        M_iter, K_exec, N_size, stream[j], startEvent, stopEvent);
                      
            #if !defined(MEASURES)
                printMatrix(C, M_iter, N_size, ms);
            #else
                printResults(ms);
            #endif

            msSum+=ms;
        }   
    }
    streamDestroy(stream,Nstr);
    free(C);
    cudaFree(Ad);
    cudaFree(Bd);
    cudaFree(Cd);
    end=std::chrono::system_clock::now();

#elif BLURBOX
    unsigned int width, height;
    float ms=0, elapsed=0;
    const char* input_path = "/home/cecconi/GPUfarm/images/in/";
    const char* output_path = "/home/cecconi/GPUfarm/images/out/";

    std::cout<<std::endl<<std::endl<<"#BLURBOX,";
    #ifndef MEASURES
    printInfos();
    #endif
    std::cout<<std::endl;

    start=std::chrono::system_clock::now();

    cudaEvent_t startEvent, stopEvent;  
    checkCuda( cudaEventCreate(&startEvent) );
    checkCuda( cudaEventCreate(&stopEvent) );

    cudaStream_t *stream=streamCreate(Nstr);

    int j;
    for (j=0; j<Nstr; ++j){
        for (const auto &entry : std::experimental::filesystem::directory_iterator(input_path))
        {
            std::string fname = entry.path().string().substr(entry.path().string().find_last_of('/') + 1);
            #ifndef MEASURES
            std::cout<<std::endl<<fname.c_str()<<std::endl;
            #endif
            const char * input_file=entry.path().c_str();
            std::vector<unsigned char> in;

            // Load the data
            unsigned error = lodepng::decode(in, width, height, input_file);
            if(error) 
                std::cout << "decoder error " << error << ": " //<< lodepng_error_text(error) 
                    << std::endl;
            bytesSize=width*height*sizeof(unsigned char);

            // Prepare the data
            unsigned char* input_image = new unsigned char[in.size()];
            unsigned char* output_image = new unsigned char[in.size()];

            checkCuda(cudaMallocManaged(&input_image, in.size()));
            checkCuda(cudaMallocManaged(&output_image, in.size()));

            unsigned char* alphaChannel = new unsigned char[in.size()/4];
            int count=0,where=0;
            for(int i = 0; i < in.size(); ++i) {
                if((i+1) % 4 != 0) {
                    input_image[where] = in.at(i);
                    ++where;
                }                
                else
                {
                    alphaChannel[count] = in.at(i);
                    ++count;
                }
                output_image[i] = 255;
            }

            ms = blurBoxFilter( input_image, output_image, width, height, 
                                stream[j],startEvent,stopEvent);

            // Prepare data for output
            count=0;
            std::vector<unsigned char> out;
            for(int i = 0; i < in.size(); ++i) {
                out.push_back(output_image[i]);
                if((i+1) % 3 == 0) {
                    out.push_back(alphaChannel[count]);
                    ++count;
                }
            }

            // Output the data
            std::string s(output_path);
            s.append(fname.c_str());
            const char * out_fname=s.c_str();

            error = lodepng::encode(out_fname, out, width, height);
            if(error) 
                std::cout << "encoder error " << error << ": "//<< lodepng_error_text(error) 
                    << std::endl;

            printResults(ms);
            msSum+=ms;
        }
    }    
    streamDestroy(stream,Nstr);
    end=std::chrono::system_clock::now();  

#elif BLURGAUSS
    unsigned int width, height;
    float ms=0, elapsed=0;
    //const char* input_path = "/home/cecconi/GPUfarm/gpu_farm/images/in/";
    //const char* output_path = "/home/cecconi/GPUfarm/gpu_farm/images/out/";
    const char* input_path = "/home/cecconi/GPUfarm/images/in/";
    const char* output_path = "/home/cecconi/GPUfarm/images/out/";

    std::cout<<std::endl<<std::endl<<"#BLURFILTER,";
    #ifndef MEASURES
    printInfos();
    #endif

    start=std::chrono::system_clock::now();

    cudaEvent_t startEvent, stopEvent;  
    checkCuda( cudaEventCreate(&startEvent) );
    checkCuda( cudaEventCreate(&stopEvent) );



    cudaStream_t *stream=streamCreate(Nstr);

    int j;
    for (j=0; j<Nstr; ++j){
    for (const auto &entry : std::experimental::filesystem::directory_iterator(input_path))
        {
            std::string fname = entry.path().string().substr(entry.path().string().find_last_of('/') + 1);

            const char * input_file=entry.path().c_str();
            std::vector<unsigned char> in;
        
            // Load the data
            unsigned error = lodepng::decode(in, width, height, input_file);
            if(error) std::cout << "decoder error " << error << ": " //<< lodepng_error_text(error) 
            << std::endl;
            bytesSize=width*height*sizeof(unsigned char);
    
            // Prepare the data
            unsigned char* input_image = new unsigned char[in.size()];
            unsigned char* output_image = new unsigned char[in.size()];

            checkCuda(cudaMallocManaged(&input_image, bytesSize));
            checkCuda(cudaMallocManaged(&output_image, bytesSize));

            int where = 0;
            for(int i = 0; i < in.size(); ++i) {
                if((i+1) % 4 != 0) {
                    input_image[i] = in.at(i);
                    output_image[i] = 255;
                }   
            }

            ms =  blurGaussianfilter (input_image, output_image,
                    width, height, 5, 4.0,//int kerdim, float sigma,
                    stream[j],startEvent,stopEvent);

            // Prepare data for output
            std::vector<unsigned char> out;
            for(int i = 0; i < in.size(); ++i) {
                out.push_back(output_image[i]);
                /*if((i+1) % 3 == 0) {
                    out.push_back(255);
                }*/
            }
        
            // Output the data
            std::string s(output_path);
            s.append(fname.c_str());
            const char * out_fname=s.c_str();

            error = lodepng::encode(out_fname, out, width, height);
            if(error) std::cout << "encoder error " << error << ": "<< lodepng_error_text(error) << std::endl;

            printResults(ms);
            msSum+=ms;
        }
    }
    
    streamDestroy(stream,Nstr);
    end=std::chrono::system_clock::now();     
#endif

    std::chrono::duration<double, std::milli> millis = end - start;   
    printTotalTimes(msSum,  millis.count() );

    return 0;
}

