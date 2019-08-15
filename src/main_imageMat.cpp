#include <math.h>
#include <string.h>  
#include <ctime>
#include <vector>
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
        std::cout << N <<" \t \t " << BLOCK << " \t \t " << GRIDx << std::endl;
    }
    else {
        std::cout << "A size \t\t B size \t C size"<< std::endl;
        std::cout<< M<<"x"<<K <<"\t\t"<< K<<"x"<<N <<"\t\t"<< M<<"x"<<N <<std::endl;
    
        std::cout<< std::endl << "Block Dim \t Grid X Dim \t Grid Y Dim" << std::endl;
        std::cout<< BLOCK << " \t \t "<< GRIDx << " \t \t "<< GRIDy <<std::endl;
    }       
    
#endif     
}

void printImageInfos(int width,int height){
#ifndef MEASURES
    std::cout << "Image WIDTH \t Image HEIGHT \t Block Dim \t Grid Dim " << std::endl;
    std::cout << width <<" \t \t " << height <<" \t \t " << BLOCK << " \t \t " << GRIDx << std::endl;    
#endif     
}


void printResults(float ms){
    float rb_wb=bytesSize*2 + GRIDx*sizeof(float); 
    std::cout <<"*"<< ms<< ","<< (rb_wb/ms/1e6)<<std::endl; 
}


void printTotalTimes(float eventsTime, float hostTime){ //è uguale a quello di cos, c'è il modo di metterlo da qualche parte e poi richiamarlo n volte?
    int rb_wb = bytesSize*2 + GRIDx*sizeof(float); //?????
    std::cout<<std::endl<<"----Total Device Events measures: "<< eventsTime<<"ms"<<std::endl;
    std::cout<<std::endl<<"----Total Host measures: "<< hostTime <<"ms"<<std::endl;
    std::cout<<std::endl<<"----Effective Bandwidth: "<< (rb_wb/eventsTime/1e6)<<"GB/s"<<std::endl;     
}


void printMatrix(float *Cmat,int m, int n){ 
    for (int i = 0; i < m; ++i)
    {
        for (int j = 0; j < n; ++j){
            float val=getMatrixVal(Cmat,i,j,n);
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
                sum += getMatrixVal( A,i,l,K )*getMatrixVal( B,l,j,N ); 

            setMatrixVal( C,i,j,N,sum );
        } 
    }
}


void printMeasures(bool square, std::string label, float msTot, float chr, int matN, int devId){
    //posso usare prop per prendere il devID???
    if(square)
        std::cout<< label <<","<< msTot <<","<< chr <<","             //outputs
                << 1 <<","<< N <<","<< matN <<","        //input
                << devId <<","<< BLOCK <<","<< GRIDx <<std::endl;     //gpu infos
    else
        std::cout<< label <<","<< msTot <<","<< chr <<","                           //outputs
                << 0 <<","<< M <<","<< K <<","<< N <<","<< matN <<"," //input
                << devId <<","<< BLOCK <<","<< GRIDx <<","<< GRIDy <<std::endl;     //gpu infos     
}

void printImgMeasures(std::string label, float msTot, float chr, int imageN, int devId){
    std::cout<< label <<","<< msTot <<","<< chr <<","               //outputs
            << imageN <<","    //input
            << devId <<","<< BLOCK <<std::endl;                     //gpu infos     
}


void checkMatEquality(float *A, float *B, int M, int N){    
    bool equal=true;  
    //std::cout<<"------CORRECTNESS CHECK------"<<std::endl;
    for(int i=0; i<M; ++i) {
        for(int j=0; j<N; ++j) {
            //std::cout<<getMatrixVal( A,i,j,N )<<","<<getMatrixVal( B,i,j,N )<<" | ";
            if (getMatrixVal( A,i,j,N ) != getMatrixVal( B,i,j,N )){
                equal=false;
                break;
            }  
                        
        } 
        // std::cout<<std::endl; 
        if(!equal)
           break;
    }
    if(!equal)
        std::cout<< " NOT EQUAL matrices "<<std::endl<< std::endl;
    else
        std::cout<< " EQUAL matrices "<<std::endl<< std::endl;
}


inline void divideAlphaChannel(unsigned char* inImage, unsigned char* alphaChannel, std::vector<unsigned char> in){
    int count=0,where=0;
    for(int i = 0; i < in.size(); ++i) {
        if((i+1) % 4 != 0)  {
            inImage[where] = in.at(i);
            ++where;
        }                
        else {
            alphaChannel[count] = in.at(i);
            ++count;
        }
    }
}


inline std::vector<unsigned char> rebuildAlphaChannel(unsigned char*outImg, unsigned char*alphaChannel, int size){
    int count=0;
    std::vector<unsigned char> out;
    for(int i = 0; i < size; ++i) {
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
    
    std::string label;
    int maxThreads = 2048;
    int gpu_clk = 1;    
    float msTot = 0.0f;
    //int nStream = 3;
    std::chrono::system_clock::time_point start, end;
    std::chrono::duration<double, std::milli> millis;  

    //args
    int devId = atoi(argv[1]);    
    BLOCK = atoi(argv[2]);    
    const int nStreams = atoi(argv[3]);
    //int hyb = atoi(argv[5]);
     
    gpuErrchk( cudaDeviceGetAttribute(&gpu_clk, cudaDevAttrClockRate, devId));    
    gpuErrchk( cudaSetDevice(devId) );
    gpuErrchk( cudaGetDeviceProperties(&prop, devId));   
    

    #ifdef LOWPAR
        label="LOW";
    #else
        label="";
    #endif  

    //event and stream creation
    cudaEvent_t startEvent, stopEvent;
    cudaStream_t stream[nStreams];
    streamCreate(stream, nStreams);

/*** MATMUL ***/
#ifdef MATMUL
    label+="MATMUL";
    //args
    if (argc<6|| argc>9){
        return 1;
    }
    bool square = atoi(argv[4]);
    int matN = atoi(argv[5]);
    if(square){
        N = atoi(argv[6]);        
        M = N;
        K = N;
    }
    else{
        M = atoi(argv[6]);
        K = atoi(argv[7]);
        N = atoi(argv[8]);
    }
    #ifndef MEASURES
        printInfos(square); 
    #endif
     
    float *A, *B, *C;
    float *Ad, *Bd, *Cd;
    const int bytesA = M*K*sizeof(float);
    const int bytesB = K*N*sizeof(float);
    const int bytesC = M*N*sizeof(float);

    start=std::chrono::system_clock::now();
    if (nStreams==0)
    {        
        //device mem allocation       
        gpuErrchk( cudaMalloc((void **)&Ad, bytesA) );
        gpuErrchk( cudaMalloc((void **)&Bd, bytesB) );
        gpuErrchk( cudaMalloc((void **)&Cd, bytesC) );
        //host mem alloc
        A = (float *)calloc(matN, bytesA);
        B = (float *)calloc(matN, bytesB);
        C = (float *)calloc(matN, bytesC);
        //host data init
        for(int i=0; i<matN; ++i){
            randomMatrix(M, K, A+(i*M*K));
            randomMatrix(K, N, B+(i*K*N));
        } 
        //event start
        createAndStartEvent(&startEvent, &stopEvent);
        if (square){          
            label += "SQUARE";
            int size = N*N;
            for (int i = 0; i < matN; ++i) { 
                int idx = i*size;
                //kernel call
                newSquareMatMulKer(A+idx, B+idx, C+idx, Ad, Bd, Cd, N);         
            }
        }
        else{
            label += "NONSQUARE";
            int sizeA = M*K;
            int sizeB = K*N;
            int sizeC = M*N;
            for (int i = 0; i < matN; ++i) { 
                int idxA = i*sizeA;
                int idxB = i*sizeB;
                int idxC = i*sizeC;
                //kernel call
                newMatMulKer(A+idxA, B+idxB, C+idxC, Ad, Bd, Cd, M, K, N);
            }
        }        
    }
    else
    {
        //device mem allocation
        gpuErrchk( cudaMalloc((void **)&Ad, bytesA*nStreams) );
        gpuErrchk( cudaMalloc((void **)&Bd, bytesB*nStreams) );
        gpuErrchk( cudaMalloc((void **)&Cd, bytesC*nStreams) );
        //host pinned mem allocation
        gpuErrchk( cudaMallocHost((void **)&A, bytesA*matN) );
        gpuErrchk( cudaMallocHost((void **)&B, bytesB*matN) );
        gpuErrchk( cudaMallocHost((void **)&C, bytesC*matN) );
        //host data init
        for(int i=0; i<matN; ++i){
            randomMatrix(M, K, A+(i*M*K));
            randomMatrix(K, N, B+(i*K*N));
        } 
        //event start
        createAndStartEvent(&startEvent, &stopEvent);
        if (square){          
            label += "SQUARE";
            int size = N*N;
            for (int i = 0; i < matN; ++i) { 
                int j = i%nStreams;            
                int idx = i*size;
                int streamOffs = j*size;
                //kernel call
                newSquareMatMulKer(A+idx, B+idx, C+idx, Ad+streamOffs, Bd+streamOffs, Cd+streamOffs, 
                                    N, stream[j]);         
            }
        }
        else{
            label += "NONSQUARE";
            int sizeA = M*K;
            int sizeB = K*N;
            int sizeC = M*N;
            for (int i = 0; i < matN; ++i) { 
                int j = i%nStreams;   
                int strOffsA = j*sizeA;
                int strOffsB = j*sizeB;
                int strOffsC = j*sizeC;
                //kernel call
                newMatMulKer(A+(i*sizeA), B+(i*sizeB), C+(i*sizeC), Ad+strOffsA, Bd+strOffsB, Cd+strOffsC,
                                M, K, N, stream[j]);
            }
        }                
    }
    msTot = endEvent(&startEvent, &stopEvent);
    end = std::chrono::system_clock::now();
    millis = end - start;    
    #ifdef MEASURES          
        printMeasures(square, label, msTot, millis.count(), matN, devId);
    #else
        printInfos(square);

        float *_A, *_B, *_C, *tmpC;
        tmpC = (float *)calloc(1,bytesC);
        for (int s=0; s<matN; ++s)
        {          
            _A = A+(s*M*K);
            _B = B+(s*K*N);
            _C = C+(s*M*N);
            memset(tmpC, 0, bytesC);

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


/*** BLURBOX ***/
#elif BLURBOX
    label += "BLURBOX";
    unsigned int width, height;
    const char* input_path = "/home/cecconi/GPUfarm/images/in/";
    const char* output_path = "/home/cecconi/GPUfarm/images/out/";

    #ifndef MEASURES
        std::cout<<"Device : "<< prop.name <<std::endl;
        std::cout<<"multiproc num : "<< prop.multiProcessorCount <<std::endl;
        std::cout<<"warp size : "<< prop.warpSize <<std::endl;
    #endif

    start=std::chrono::system_clock::now();
    createAndStartEvent(&startEvent, &stopEvent);    
    
    int k = 0;

    for (const auto &entry : std::experimental::filesystem::directory_iterator(input_path))
    {
        int j = k%nStream;
        std::string fname = entry.path().string().substr(entry.path().string().find_last_of('/') + 1);
        #ifndef MEASURES
            std::cout<<std::endl<<"----------"<<std::endl<<fname.c_str()<<std::endl;
        #endif
        const char * input_file=entry.path().c_str();
        std::vector<unsigned char> in;

        //load the data
        unsigned error = lodepng::decode(in, width, height, input_file);
        if(error) 
            std::cout<<"decoder error "<< error <<": "<< lodepng_error_text(error)<< std::endl;

        //prepare the data
        int imgBytes=width*height*3;
        unsigned char *input_image, *output_image;
        gpuErrchk( cudaMallocHost((void **)&input_image, imgBytes) );
        gpuErrchk( cudaMallocHost((void **)&output_image, imgBytes) );
        unsigned char *input_d, *output_d;
        gpuErrchk( cudaMalloc((void **)&input_d, imgBytes) );
        gpuErrchk( cudaMalloc((void **)&output_d, imgBytes) );

        unsigned char* alphaChannel = new unsigned char[in.size()/4];
        divideAlphaChannel(input_image, alphaChannel, in);

        blurBoxFilter( input_image, output_image, input_d, output_d, width, height, imgBytes, stream[j] );
        
        std::vector<unsigned char> out=rebuildAlphaChannel(output_image, alphaChannel,  imgBytes);

        //output the data
        std::string s(output_path);
        s.append(fname.c_str());
        const char * out_fname=s.c_str();
        error = lodepng::encode(out_fname, out, width, height);
        if(error) 
            std::cout<<"encoder error "<< error <<": "<< lodepng_error_text(error) <<std::endl;

        ++k;
        #ifndef MEASURES
            printImageInfos( width, height);
        #endif

        cudaFreeHost(input_image);
        cudaFreeHost(output_image);
        cudaFree(input_d);
        cudaFree(output_d);
    }
    msTot = endEvent(&startEvent, &stopEvent);
    end = std::chrono::system_clock::now();
    millis = end - start;

    #ifdef MEASURES          
        printImgMeasures(label, msTot, millis.count(), k, devId);     
    #endif    

/*** BLURGAUSS ***/
#elif BLURGAUSS
    label += "BLURGAUSS";
    unsigned int width, height;
    const char* input_path = "/home/cecconi/GPUfarm/images/in/";
    const char* output_path = "/home/cecconi/GPUfarm/images/out/";
    const int kerDim = 5;
    const float sigma = 4.0;

    #ifndef MEASURES
        std::cout<<"Device : "<< prop.name <<std::endl;
        std::cout<<"multiproc num : "<< prop.multiProcessorCount <<std::endl;
        std::cout<<"warp size : "<< prop.warpSize <<std::endl;
    #endif

    start=std::chrono::system_clock::now();
    createAndStartEvent(&startEvent, &stopEvent);  

    //Gaussian filter mat
    int kerBytes = kerDim*kerDim*sizeof(float);
    float *ker, *ker_d;
    gpuErrchk(cudaMallocHost(&ker, kerBytes));
    gpuErrchk(cudaMalloc(&ker_d, kerBytes));

    getGaussian(ker, kerDim, sigma); 
    gpuErrchk( cudaMemcpy(ker_d, ker, kerBytes, cudaMemcpyHostToDevice) );    


    int k=0;
    for (const auto &entry : std::experimental::filesystem::directory_iterator(input_path))
    {
        int j = k%nStream;
        std::string fname = entry.path().string().substr(entry.path().string().find_last_of('/') + 1);
        #ifndef MEASURES
            std::cout<<std::endl<<"----------"<<std::endl<<fname.c_str()<<std::endl;
        #endif

        const char * input_file=entry.path().c_str();
        std::vector<unsigned char> in;
    
        //load data
        unsigned error = lodepng::decode(in, width, height, input_file);
        if(error) std::cout << "decoder error " << error << ": " << lodepng_error_text(error) << std::endl;

        int imgBytes = width*height*3;
        unsigned char *input_image, *output_image;
        gpuErrchk( cudaMallocHost((void **)&input_image, imgBytes) );
        gpuErrchk( cudaMallocHost((void **)&output_image, imgBytes) );
        unsigned char *input_d, *output_d;
        gpuErrchk( cudaMalloc((void **)&input_d, imgBytes) );
        gpuErrchk( cudaMalloc((void **)&output_d, imgBytes) );

        unsigned char* alphaChannel = new unsigned char[in.size()/4];
        divideAlphaChannel(input_image, alphaChannel, in);
        std::cout<<std::endl<< in.size()<<std::endl;

        blurGaussianfilter (input_image, output_image, input_d, output_d, ker_d, width, height, imgBytes,
                            kerDim, stream[j]);

        std::vector<unsigned char> out = rebuildAlphaChannel(output_image, alphaChannel, imgBytes);
        std::cout<<std::endl<< out.size()<<std::endl;

        // Output the data
        std::string s(output_path);
        s.append(fname.c_str());
        const char * out_fname=s.c_str();

        error = lodepng::encode(out_fname, out, width, height);
        if(error) std::cout << "encoder error " << error << ": "<< lodepng_error_text(error) << std::endl;

        ++k;

        #ifndef MEASURES
            printImageInfos( width, height);
        #endif

        cudaFreeHost(input_image);
        cudaFreeHost(output_image);
        cudaFree(input_d);
        cudaFree(output_d);

    }
    msTot = endEvent(&startEvent, &stopEvent);
    end = std::chrono::system_clock::now();
    millis = end - start;

    #ifdef MEASURES          
        printMeasures(square, label, msTot, millis.count(), matN, devId);  
    #endif    
   
    //free Host and Device space
    cudaFree(ker_d);
    cudaFreeHost(ker);
#endif

    //STREAM destruction
    streamDestroy(stream,nStreams);
    #ifndef MEASURES 
        printTotalTimes(msTot,  millis.count() );
    #endif
    cudaDeviceReset();
    return 0;
}