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

int K=0;
int M=0;
int N=0;
int bytesSize;


void printInfos(bool square){
#ifndef MEASURES
    std::cout<<"Device : "<< prop.name <<std::endl;
    std::cout<<"multiproc num : "<< prop.multiProcessorCount <<std::endl;
    std::cout<<"warp size : "<< prop.warpSize <<std::endl;

    if(square){
        std::cout << "Matrix order \t Block Dim \t Grid Dim " << std::endl;
        std::cout << N <<" \t \t \t " << BLOCK << " \t \t \t " << GRIDx << std::endl;
    }
    else {
        std::cout << "A size \t B size \t C size \t Block Dim \t Grid X Dim \t Grid Y Dim" << std::endl;
        std::cout<< M<<"x"<<K <<"\t"<< K<<"x"<<N <<"\t"<< M<<"x"<<N <<"\t" << BLOCK << " \t \t \t "<< GRIDx << " \t \t \t "<< GRIDy <<std::endl;
    }       
#endif     
}


void printResults(float ms){
    float rb_wb=bytesSize*2 + GRIDx*sizeof(float); 
    std::cout <<"*"<< ms<< ","<< (rb_wb/ms/1e6)<<std::endl; 
}


void printTotalTimes(float eventsTime, float hostTime){ //è uguale a quello di cos, c'è il modo di metterlo da qualche parte e poi richiamarlo n volte?
    int rb_wb = bytesSize*2 + GRID*sizeof(float); //?????
    std::cout<<std::endl<<"----Total Device Events measures: "<< eventsTime<<"ms"<<std::endl;
    std::cout<<std::endl<<"----Total Host measures: "<< hostTime <<"ms"<<std::endl;
    std::cout<<std::endl<<"----Effective Bandwidth: "<< (rb_wb/ms/1e6)<<"GB/s"<<std::endl;     
}


void printMatrix(float *Cmat,int m, int n){ 
    for (int i = 0; i < m; ++i)
    {
        for (int j = 0; j < n; ++j){
            float val=getMatrixVal<float>(Cmat,i,j,n);
            std::cout<<val << "  ";
        }            
        std::cout<<std::endl;
    }      
}


void hostMatMul(float *A, float *B, float *C, int M, int K, int N){
    for(int i=0; i<M; ++i){ //M = r1    
        for(int j=0; j<N; ++j){ //N = c2        
            float sum=0.0f;
            for(int l=0; l<K; ++l) //K = c1                            
                sum += getMatrixVal<float>( A,i,l,K )*getMatrixVal<float>( B,l,j,N );

            setMatrixVal( C,i,j,N,sum );
        } 
    }
}


void printMeasures(bool square, std::string label, float msTot, float chr, int matN, int iters, int devId){
    //posso usare prop per prendere il devID???
    if(square)
        std::cout<< label <<","<< msTot <<","<< chr <<","             //outputs
                << N <<","<< matN <<","<< 1 <<","<< iters<<","        //input
                << devId <<","<< BLOCK <<","<< GRIDx <<std::endl;     //gpu infos
    else
        std::cout<< label <<","<< msTot <<","<< chr <<","                           //outputs
                << M <<","<< K <<","<< N <<","<< matN <<","<< 0 <<","<< iters <<"," //input
                << devId <<","<< BLOCK <<","<< GRIDx <<","<< GRIDy <<std::endl;     //gpu infos     
}

/*void checkMatMul(float *A, float *B, float *C, int N){
    //std::cout<< std::endl<< "CHECK FOR - C - MATRIX "<<std::endl;

    for(int i=0; i<N; ++i) 
    {
        for(int j=0; j<N; ++j) 
        {
            float sum=0.0f;
            for(int l=0; l<N; ++l)                           
                sum += getMatrixVal<float>( A,i,l,N )*getMatrixVal<float>( B,l,j,N );

            setMatrixVal( C,i,j,N,sum );
        } 
    }
    //printMatrix(C, M, N, 0); 
}*/

void checkMatEquality(float *A, float *B, int M, int N){    
    bool equal=true;  
    for(int i=0; i<M; ++i) {
        for(int j=0; j<N; ++j) {
            if (getMatrixVal<float>( A,i,j,N ) != getMatrixVal<float>( B,i,j,N )){
                equal=false;
                break;
            }                
        } 
        if(!equal)
            break;
    }
    if(!equal)
        std::cout<< std::endl<< " NOT EQUAL matrices "<<std::endl;
    else
        std::cout<< std::endl<< " EQUAL matrices "<<std::endl;
}


void divideAlphaChannel(char* inImage, char* outImage, unsigned char* alphaChannel, std::vector<unsigned char> in){
    
    int count=0,where=0;
    for(int i = 0; i < in.size(); ++i) {
        if((i+1) % 4 != 0) {
            inImage[where] = in.at(i);
            ++where;
        }                
        else
        {
            alphaChannel[count] = in.at(i);
            ++count;
        }
        outImage[i] = 255; //dopo vedere se lo posso togliere e farlo tipo come con calloc ma che setti tutto a 255 invece di 0
    }
}


std::vector<unsigned char> rebuildAlphaChannel(unsigned char*outImg, unsigned char*alphaChannel){
    // Prepare data for output
    int count=0;
    std::vector<unsigned char> out;
    for(int i = 0; i < in.size(); ++i) {
        out.push_back(outImg[i]);
        if((i+1) % 3 == 0) {
            out.push_back(alphaChannel[count]);
            ++count;
        }
    }
    return out;
}


int main(int argc, char **argv){
    std::srand(static_cast <unsigned> (time(NULL)));

    int gpu_clk = 1;
    std::string label;
    float msTot = 0.0f;
    int nStream = 3;
    std::chrono::system_clock::time_point start, end;
    std::chrono::duration<double, std::milli> millis;  

    //args
    int devId = atoi(argv[1]);    
    BLOCK = atoi(argv[2]);    
    int iters = atoi(argv[3]);

    bytesSize = N*sizeof(float); 
     
    checkCuda(cudaDeviceGetAttribute(&gpu_clk, cudaDevAttrClockRate, devId));    
    checkCuda( cudaSetDevice(devId) );
    checkCuda( cudaGetDeviceProperties(&prop, devId));     

    //EVENT creation
    cudaEvent_t startEvent, stopEvent;
    /*checkCuda( cudaEventCreate(&startEvent) );
    checkCuda( cudaEventCreate(&stopEvent) );

    cudaEvent_t startTot, stopTot;
    checkCuda( cudaEventCreate(&startTot) );
    checkCuda( cudaEventCreate(&stopTot) );*/

    //STREAM creation
    cudaStream_t *stream=streamCreate(nStream);

/*** MATMUL ***/
#ifdef MATMUL
    int matN;
    //other args
    bool square = atoi(argv[4]);
    if(square){
        N = atoi(argv[5]);
        matN = atoi(argv[6]);
        M = N;
        K = N;
    }
    else{
        M = atoi(argv[5]);
        K = atoi(argv[6]);
        N = atoi(argv[7]);
        matN = atoi(argv[8]);
    }

    int chunk = matN/iters;    
    #ifdef LOWPAR
        GRIDx= 1;
        GRIDy= 1;
        label="LOW";
    #else
        //dim3 dimGrid((B.width + dimBlock.x - 1) / dimBlock.x,
                    //(A.height + dimBlock.y - 1) / dimBlock.y);

        int sizeY = M*chunk;
        int sizeX = N*chunk;
        GRIDx = ceil((sizeX)/BLOCK);
        GRIDy = ceil((sizeY)/BLOCK);
        label="";
    #endif

    if(chunk==1)
        label += "SINGLEMATMUL";
    else
        label += "CHUNKMATMUL";
  
    //chrono start
    start=std::chrono::system_clock::now();
    
    const int bytesA = M*K*sizeof(float);
    const int bytesB = K*N*sizeof(float);
    const int bytesC = M*N*sizeof(float);

    //device mem allocation
    float *Ad, *Bd, *Cd;// = (float*)calloc(chunk, bytesA);
    checkCuda( cudaMalloc((void **)&Ad, bytesA*matN) );
    checkCuda( cudaMalloc((void **)&Bd, bytesB*matN) );
    checkCuda( cudaMalloc((void **)&Cd, bytesC*matN) );

    /*checkCuda( cudaMalloc((void **)&Ad, bytesA*chunk) );
    checkCuda( cudaMalloc((void **)&Bd, bytesB*chunk) );
    checkCuda( cudaMalloc((void **)&Cd, bytesC*chunk) );*/

    //host pinned mem allocation
    float *A, *B, *C;
    checkCuda( cudaMallocHost((void **)&A, bytesA*matN) );
    checkCuda( cudaMallocHost((void **)&B, bytesB*matN) );
    checkCuda( cudaMallocHost((void **)&C, bytesC*matN) );
    //host data init
    for(int i=0; i<matN; ++i){
        randomMatrix(M, K, &A[i*M*K]);
        randomMatrix(K, N, &B[i*K*N]);
    } 

    //event start
    createAndStartEvent(startEvent, stopEvent);
    //checkCuda( cudaEventRecord(startTot,0) );

    for (int i = 0; i < iters; ++i) { 
        int j = i%nStream;
            if(square){
                int size = N*N;
                ms = newSquareMatMulKer(&A[i*size*chunk], &B[i*size*chunk], &C[i*size*chunk], 
                            //Ad, Bd, Cd, N, chunk,
                            &Ad[i*size*chunk], &Bd[i*size*chunk], &Cd[i*size*chunk], N, chunk,
                            stream[j], startEvent, stopEvent);  //ms = newSquareMatMulKer(&Ad[i*size], &Bd[i*size], &Cd[i*size], N, chunk, stream[j], startEvent, stopEvent);
            }
            else{
                int sizeA = M*K;
                int sizeB = K*N;
                int sizeC = M*N;
                ms = newMatMulKer(&A[i*sizeA*chunk], &B[i*sizeB*chunk], &C[i*sizeC*chunk], //A, B, C, Ad, Bd, Cd, 
                            //Ad, Bd, Cd,
                            &Ad[i*sizeA*chunk], &Bd[i*sizeB*chunk], &Cd[i*sizeC*chunk],
                            M, K, N, chunk, stream[j], startEvent, stopEvent); //ms = newMatMulKer(&Ad[i*M*K], &Bd[i*K*N], &Cd[i*M*N], M, K, N, chunk, stream[j], startEvent, stopEvent);  
            }
        }  
    //events stop
    /*checkCuda( cudaEventRecord(stopTot, 0) );
    checkCuda( cudaEventSynchronize(stopTot) );
    checkCuda( cudaEventElapsedTime(&msSum, startTot, stopTot) );*/
    msTot = endEvent(stopEvent);
    //chrono end
    end = std::chrono::system_clock::now();
    millis = end - start;

    #ifdef MEASURES
        if(square)
            label += "SQUARE";
        else
            label += "NONSQUARE";
        printMeasures(square, label, msTot, millis.count(), matN, iters, devId);
    #else
        for (int s = 0; s < matN; s++)
        {
            float *_A = &A[s*M*K];
            float *_B = &B[s*K*N];
            float *_C = &C[s*M*N];
            float *tmpC;
            hostMatMul(_A, _B, tmpC, M, K, N);
            checkMatEquality(_C, tmpC, M, N);
        }
        
        
    #endif
    
    //free Host and Device space
    cudaFreeHost(A);
    cudaFreeHost(B);
    cudaFreeHost(C);
    cudaFree(Ad);
    cudaFree(Bd);
    cudaFree(Cd);

#elif BLURBOX
    label = "BLURBOX";
    unsigned int width, height;
    const char* input_path = "/home/cecconi/GPUfarm/images/in/";
    const char* output_path = "/home/cecconi/GPUfarm/images/out/";
    
    #ifndef MEASURES
    printInfos(square);
    #endif
    std::cout<<std::endl;

    start=std::chrono::system_clock::now();
    int k = 0;
    //for (int j=0; j<Nstr; ++j){
    createAndStartEvent(startEvent,stopEvent);
    for (const auto &entry : std::experimental::filesystem::directory_iterator(input_path))
    {
        int j = k%nStream;
        std::string fname = entry.path().string().substr(entry.path().string().find_last_of('/') + 1);
        #ifndef MEASURES
            std::cout<<std::endl<<fname.c_str()<<std::endl;
        #endif
        const char * input_file=entry.path().c_str();
        std::vector<unsigned char> in;

        // Load the data
        unsigned error = lodepng::decode(in, width, height, input_file);
        if(error) 
            std::cout<<"decoder error "<< error <<": "<< lodepng_error_text(error)<< std::endl;

        bytesSize=width*height*sizeof(unsigned char);

        // Prepare the data
        unsigned char* input_image = new unsigned char[in.size()];
        unsigned char* output_image = new unsigned char[in.size()];

        checkCuda(cudaMallocManaged(&input_image, in.size()));
        checkCuda(cudaMallocManaged(&output_image, in.size()));

        unsigned char* alphaChannel = new unsigned char[in.size()/4];
        divideAlphaChannel(input_image, output_image, alphaChannel, in);
        /*int count=0,where=0;
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
        }*/


        ms = blurBoxFilter( input_image, output_image, width, height, 
                            stream[j],startEvent,stopEvent);


        /* checkCuda( cudaEventRecord(stopTot, 0) );
        checkCuda( cudaEventSynchronize(stopTot) );
        checkCuda( cudaEventElapsedTime(&tmp, startTot, stopTot) );*/

        // Prepare data for output
        /*count=0;
        std::vector<unsigned char> out;
        for(int i = 0; i < in.size(); ++i) {
            out.push_back(output_image[i]);
            if((i+1) % 3 == 0) {
                out.push_back(alphaChannel[count]);
                ++count;
            }
        }*/
        out = rebuildAlphaChannel(output_image, alphaChannel);

        // Output the data
        std::string s(output_path);
        s.append(fname.c_str());
        const char * out_fname=s.c_str();

        error = lodepng::encode(out_fname, out, width, height);
        if(error) 
            std::cout<<"encoder error "<< error <<": "<< lodepng_error_text(error) <<std::endl;

        printResults(ms);
        //msSum+=tmp;
        //msTot+=ms;
        ++k;
    }
        msTot = endEvent(stopEvent);
   // }    
    //streamDestroy(stream,nStream);
    end=std::chrono::system_clock::now();  







#elif BLURGAUSS
    unsigned int width, height;
    float ms=0, elapsed=0,tmp=0;
    const char* input_path = "/home/cecconi/GPUfarm/images/in/";
    const char* output_path = "/home/cecconi/GPUfarm/images/out/";

    std::cout<<std::endl<<std::endl<<"#BLURFILTER,";
    #ifndef MEASURES
    printInfos(square);
    #endif

    start=std::chrono::system_clock::now();

    for (int j=0; j<Nstr; ++j){
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


            checkCuda( cudaEventRecord(startTot,0) );

            //checkCuda(cudaMallocManaged(&input_image, bytesSize));
            //checkCuda(cudaMallocManaged(&output_image, bytesSize));
            checkCuda(cudaMallocManaged(&input_image, in.size()));
            checkCuda(cudaMallocManaged(&output_image, in.size()));

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

            checkCuda( cudaEventRecord(stopTot, 0) );
            checkCuda( cudaEventSynchronize(stopTot) );
            checkCuda( cudaEventElapsedTime(&tmp, startTot, stopTot) );

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
    end=std::chrono::system_clock::now();     
#endif

    //STREAM destruction
    streamDestroy(stream,nStream);
    #ifndef MESURES 
        printTotalTimes(msSum,  millis.count() );
    #endif


    cudaDeviceReset();
    return 0;
}

