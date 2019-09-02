#include <math.h>
#include <string.h>  
#include <ctime>
#include <vector>
#include <iterator>
#include <experimental/filesystem>
#include <lodepng.h>
#include <imageMatrix.h>

#define HIGH 500.0f
#define LOW -500.0f

cudaDeviceProp prop;
unsigned int BLOCK=0;
unsigned int GRIDx=0;
unsigned int GRIDy=0;

unsigned int K=0;
unsigned int M=0;
unsigned int N=0;
unsigned int bytesSize;

/* ********* *
 * UTILITIES *
 * ********* */
template<typename T> inline T getMatrixVal(T *mat, int row, int col, int width)
{ return mat[row*width+col]; }

template<typename T> inline void setMatrixVal(T *mat, int row, int col, int width, T val)
{ mat[row*width+col] = val; }

void randomMatrix(const int m, int n,float *mat){
    for(int r=0; r<m; ++r)
        for(int c=0; c<n; ++c){
            int rnd = (float)std::rand();
            float val = LOW + (rnd*(HIGH-LOW)/RAND_MAX);
            setMatrixVal(mat, r, c, n, val);
        }     
}

void launchConfig(int m, int n){
    #ifdef LOWPAR
        GRIDx = 1;
        GRIDy = 1;
    #else
        /* int sizeX,sizeY;
        if (m%BLOCK == 0) sizeX = m;
        else sizeX = m+BLOCK-1;

        if (n%BLOCK == 0) sizeY = n;
        else sizeY = n+BLOCK-1;*/

        //unsigned int grid_rows = (m + BLOCK - 1) / BLOCK;
        //unsigned int grid_cols = (n + BLOCK - 1) / BLOCK;
        //dim3 dimGrid(grid_cols, grid_rows);
        GRIDx = (m + BLOCK - 1) / BLOCK;
        GRIDy = (n + BLOCK - 1) / BLOCK;

       // GRIDx = (sizeX)/BLOCK;
       // GRIDy = (sizeY)/BLOCK;
    #endif
}

/* ****************** *
 * PRINT INFORMATIONS *
 * ****************** */
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
void printInfos(){
#ifndef MEASURES
    std::cout<<"Device : "<< prop.name <<std::endl;
    std::cout<<"multiproc num : "<< prop.multiProcessorCount <<std::endl;
    std::cout<<"warp size : "<< prop.warpSize <<std::endl;
#endif     
}

void printImageInfos(int width,int height){
#ifndef MEASURES
    std::cout << "Image WIDTH \t Image HEIGHT \t Block Dim \t Grid Dim " << std::endl;
    std::cout << width <<" \t \t " << height <<" \t \t " << BLOCK << " \t \t " << GRIDx << std::endl;    
#endif     
}


/* ************* *
 * PRINT RESULTS *
 * ************* */
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


/* *********************** *
 * MATRICES EQUALITY CHECK *
 * *********************** */
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
        std::cout<< " NOT EQUAL, ";
    else
        std::cout<< " EQUAL, ";
}



/* ********************** *
 * IMG PROCESSING HELPERS *
 * ********************** */
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

std::string getOutFullFileName(std::string out_path, std::string out_name, int k){
    //std::string s(out_path);
    size_t pos = out_name.find(".");
    std::string name = out_name.substr(0,pos);
    std::string ext = out_name.substr(pos,out_name.length()-1);
    out_path.append(name.c_str());
    out_path.append(std::to_string(k));
    out_path.append(ext.c_str());

    return out_path;
}


/* ************* *
 * ************* *
 * MAIN FUNCTION *
 * ************* *
 * ************* */
int main(int argc, char **argv){
    std::srand(static_cast <unsigned> (time(NULL)));
    
    std::string label;
    float msTot = 0.0f;
    unsigned int nStreams;
    std::chrono::system_clock::time_point start, end;
    std::chrono::duration<double, std::milli> millis;  
    cudaEvent_t startEvent, stopEvent;

    // Common Args
    int devId = atoi(argv[1]);    
    BLOCK = atoi(argv[2]);    
    bool cuStr = atoi(argv[3]);
    int strNum = atoi(argv[4]);
    
    // Device ID and properties
    gpuErrchk( cudaSetDevice(devId) );
    gpuErrchk( cudaGetDeviceProperties(&prop, devId) );  
    const int maxThreads = prop.maxThreadsPerMultiProcessor;    
    

    #ifdef LOWPAR
        label="LOW";
    #else
        label="";
    #endif  



/**** MATMUL ****/
#ifdef MATMUL
    label+="MATMUL";
    //args
    if (argc<9 || argc>11){
        std::cerr << "Usage: " << argv[0] << "DeviceID, BLOCK, CudaStream, strNum Square, Shared, matNum, M [, K, N]" << std::endl;
        return 1;
    }
    bool square = atoi(argv[5]);
    bool shared = atoi(argv[6]);
    unsigned int matN = atoi(argv[7]);
    M = atoi(argv[8]);
    if(square){
        N = M;
        K = M;
    }
    else{        
        K = atoi(argv[9]);
        N = atoi(argv[10]);
    }
    //#ifndef MEASURES
      //  printInfos(square); 
    //#endif
     
    float *A, *B, *C;
    float *Ad, *Bd, *Cd;
    const unsigned int bytesA = M*K*sizeof(float);
    const unsigned int bytesB = K*N*sizeof(float);
    const unsigned int bytesC = M*N*sizeof(float);

    start=std::chrono::system_clock::now();
    if (!cuStr) //NO CUDA STREAMS
    {        
        // Device mem alloc     
        gpuErrchk( cudaMalloc((void **)&Ad, bytesA) );
        gpuErrchk( cudaMalloc((void **)&Bd, bytesB) );
        gpuErrchk( cudaMalloc((void **)&Cd, bytesC) );
        // Host mem alloc
        A = (float *)calloc(matN, bytesA);
        B = (float *)calloc(matN, bytesB);
        C = (float *)calloc(matN, bytesC);
        // Host data init
        for(int i=0; i<matN; ++i){
            randomMatrix(M, K, A+(i*M*K));
            randomMatrix(K, N, B+(i*K*N));
        }         
        // Event create and start
        createAndStartEvent(&startEvent, &stopEvent);

        if (square){   
            launchConfig(N,N);
            int size = N*N; 
            if (shared)
                label += "SHARED";
            else
                label += "SQUARE";
            for (int i = 0; i < matN; ++i) { 
                int idx = i*size;
                // Kernel caller
                squareMatMul(A+idx, B+idx, C+idx, Ad, Bd, Cd, N, shared);         
            }
            /*}
            else{
                label += "SQUARE";
                for (int i = 0; i < matN; ++i) { 
                    int idx = i*size;
                    // Kernel caller
                    squareMatMul(A+idx, B+idx, C+idx, Ad, Bd, Cd, N);         
                }
            }     */       
        }
        else{ 
            launchConfig(M,N);
            label += "NONSQUARE";
            int sizeA = M*K;
            int sizeB = K*N;
            int sizeC = M*N;
            for (int i = 0; i < matN; ++i) { 
                int idxA = i*sizeA;
                int idxB = i*sizeB;
                int idxC = i*sizeC;
                // Kernel caller
                matMul(A+idxA, B+idxB, C+idxC, Ad, Bd, Cd, M, K, N);
            }
        }    
        msTot = endEvent(&startEvent, &stopEvent);    
    }
    else{ // CUDA STREAMS
        //nStreams = prop.multiProcessorCount;
        if (strNum>1)
            nStreams = strNum;
        else
            nStreams = prop.multiProcessorCount;
        // Stream creation    
        cudaStream_t stream[nStreams];
        streamCreate(stream, nStreams);
        // Device alloc
        gpuErrchk( cudaMalloc((void **)&Ad, bytesA*nStreams) );
        gpuErrchk( cudaMalloc((void **)&Bd, bytesB*nStreams) );
        gpuErrchk( cudaMalloc((void **)&Cd, bytesC*nStreams) );
        // Host pinned alloc
        gpuErrchk( cudaMallocHost((void **)&A, bytesA*matN) );
        gpuErrchk( cudaMallocHost((void **)&B, bytesB*matN) );
        gpuErrchk( cudaMallocHost((void **)&C, bytesC*matN) );
        // Host data init
        for(int i=0; i<matN; ++i){
            randomMatrix(M, K, A+(i*M*K));
            randomMatrix(K, N, B+(i*K*N));
        } 
        // Event start
        createAndStartEvent(&startEvent, &stopEvent);
        if (square){    
            launchConfig(N,N);
            int size = N*N; 
                if (shared)
                    label += "SHARED";
                else
                    label += "SQUARE";
                
                for (int i = 0; i < matN; ++i) { 
                    int j = i%nStreams;       
                    int idx = i*size;
                    int streamOffs = j*size;
                    // Kernel caller
                    if(j==0 && i>0)
                        cudaDeviceSynchronize();  
                        //cudaStreamSynchronize(stream[j]);  
                    streamSquareMatMul(A+idx, B+idx, C+idx, Ad+streamOffs, Bd+streamOffs, Cd+streamOffs, 
                                    N, stream[j], shared);      
                }
           /* }
            else{
                label += "SQUARE";
                for (int i = 0; i < matN; ++i) { 
                    int j = i%nStreams;            
                    int idx = i*size;
                    int streamOffs = j*size;
                    // Kernel caller
                    streamSquareMatMul(A+idx, B+idx, C+idx, Ad+streamOffs, Bd+streamOffs, Cd+streamOffs, 
                                    N, stream[j]);      
                }
            }  */    
        }
        else{
            launchConfig(M,N);
            label += "NONSQUARE";
            int sizeA = M*K;
            int sizeB = K*N;
            int sizeC = M*N;
            for (int i = 0; i < matN; ++i) { 
                int j = i%nStreams;   
                int strOffsA = j*sizeA;
                int strOffsB = j*sizeB;
                int strOffsC = j*sizeC;
                // Kernel caller
                if(j==0 && i>0)
                    cudaStreamSynchronize(stream[j]); 
                streamMatMul(A+(i*sizeA), B+(i*sizeB), C+(i*sizeC), Ad+strOffsA, Bd+strOffsB, Cd+strOffsC,
                                M, K, N, stream[j]);
            }
        }     
        msTot = endEvent(&startEvent, &stopEvent);  
        streamDestroy(stream,nStreams);         
    }
    // Measures end
    
    end = std::chrono::system_clock::now();
    millis = end - start;    
    // Print results
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
        std::cout<<std::endl<< std::endl;     
        free(tmpC);
    #endif    
    // Free mem
    cudaFree(Ad);
    cudaFree(Bd);
    cudaFree(Cd);
    if(cuStr){
        cudaFreeHost(A);
        cudaFreeHost(B);
        cudaFreeHost(C);
    }
    else{
        free(A);
        free(B);
        free(C);
    }


/**** BLURBOX ****/
#elif BLURBOX
    label += "BLURBOX";

    unsigned int width = atoi(argv[5]);
    unsigned int height = atoi(argv[6]);
    unsigned int nImages = atoi(argv[7]);

    std::string input_path = "/home/cecconi/GPUfarm/images/in/";
    std::string output_path = "/home/cecconi/GPUfarm/images/out/";
    if (width==128 || width==256 || width==4096 || width==8192) {
        input_path += std::to_string(width)+"/";
        output_path += std::to_string(width)+"/";
    }
   /* else if (width==256) {
        input_path += "256/";
        output_path += "256/";
    }
    else if (width==4096) {
        input_path += "4096/";
        output_path += "4096/";
    }
    else if (width==8192) {
        input_path += "8192/";
        output_path += "8192/";
    }*/
    else{
        std::cerr<<"No available images in specified format."<<std::endl;
        return 1;
    }

    std::vector<unsigned char> in;
    std::vector<unsigned char> out;
    
    //const char* input_path = "/home/cecconi/GPUfarm/images/in/";
    //const char* output_path = "/home/cecconi/GPUfarm/images/out/";

    #ifndef MEASURES
        printInfos();
        //std::cout<<"Device : "<< prop.name <<std::endl;
        //std::cout<<"multiproc num : "<< prop.multiProcessorCount <<std::endl;
        //std::cout<<"warp size : "<< prop.warpSize <<std::endl;
    #endif

    unsigned int imgBytes = width*height*3;
    unsigned char *input_h, *output_h;
    unsigned char *input_d, *output_d;
    

    start=std::chrono::system_clock::now();  
    int k = 0;
    if (!cuStr) // NO CUDA STREAMS
    {
        gpuErrchk( cudaMalloc((void **)&input_d, imgBytes) );
        gpuErrchk( cudaMalloc((void **)&output_d, imgBytes) );

        

        createAndStartEvent(&startEvent, &stopEvent); 

        while (k<nImages)
        {              
            for (const auto &entry : std::experimental::filesystem::directory_iterator(input_path.c_str()))
            {
                input_h = new unsigned char[imgBytes];
                output_h = new unsigned char[imgBytes];
                std::string fname = entry.path().string().substr(entry.path().string().find_last_of('/') + 1);
                #ifndef MEASURES
                    std::cout<<std::endl<<"----------"<<std::endl<<fname.c_str()<<std::endl;
                #endif

                const char * input_file = entry.path().c_str();
                //std::vector<unsigned char> in;

                //load the data
                unsigned error = lodepng::decode(in, width, height, input_file);
                if(error) 
                    std::cout<<"decoder error "<< error <<": "<< lodepng_error_text(error)<< std::endl;

                //prepare the data        
                unsigned char* alphaChannel = new unsigned char[in.size()/4];
                divideAlphaChannel(input_h, alphaChannel, in);

                // Kernel launcher
                blurBoxFilter( input_h, output_h, input_d, output_d, width, height);

                //output the data
                //std::vector<unsigned char> out=rebuildAlphaChannel(output_image, alphaChannel,  imgBytes);
                out = rebuildAlphaChannel(output_h, alphaChannel,  imgBytes);
                /*std::string s(output_path);
                std::string name = fname.substr(0, s.find("."));
                std::string ext = fname.substr(1, s.find("."));
                //s.append(fname.c_str());
                s.append(name.c_str());
                s.append(std::to_string(k));
                s.append(ext.c_str());
                const char * out_fname=s.c_str();*/
                std::string s = getOutFullFileName(output_path, fname, k);
                const char *out_fname = s.c_str();
                error = lodepng::encode(out_fname, out, width, height);
                if(error) 
                    std::cout<<"encoder error "<< error <<": "<< lodepng_error_text(error) <<std::endl;

                ++k;
                #ifndef MEASURES
                    printImageInfos(width, height);
                #endif
                in.clear();
                out.clear();
                delete[] alphaChannel;
                delete[] input_h;
                delete[] output_h;
            }  
        }
        msTot = endEvent(&startEvent, &stopEvent);
        end = std::chrono::system_clock::now();
        millis = end - start;

        #ifdef MEASURES          
            printImgMeasures(label, msTot, millis.count(), k, devId);     
        #endif  
        
    }
    else{ // CUDA STREAMS
        //nStreams = prop.multiProcessorCount;
        if (strNum>1)
            nStreams = strNum;
        else
            nStreams = prop.multiProcessorCount;
        // Stream creation    
        cudaStream_t stream[nStreams];
        streamCreate(stream, nStreams);

        gpuErrchk( cudaMallocHost((void **)&input_h, imgBytes*nImages) );
        gpuErrchk( cudaMallocHost((void **)&output_h, imgBytes*nImages) );

        gpuErrchk( cudaMalloc((void **)&input_d, imgBytes*nStreams) );
        gpuErrchk( cudaMalloc((void **)&output_d, imgBytes*nStreams) );

        createAndStartEvent(&startEvent, &stopEvent); 

        while (k<nImages)
        {      
            for (const auto &entry : std::experimental::filesystem::directory_iterator(input_path.c_str()))
            {
                std::string fname = entry.path().string().substr(entry.path().string().find_last_of('/') + 1);
                #ifndef MEASURES
                    std::cout<<std::endl<<"----------"<<std::endl<<fname.c_str()<<std::endl;
                #endif
                
                int j = k%nStreams;
                
                int strOffs = j*imgBytes;

                const char *input_file = entry.path().c_str();
                //std::vector<unsigned char> in;

                //load the data
                unsigned error = lodepng::decode(in, width, height, input_file);
                if(error) 
                    std::cout<<"decoder error "<< error <<": "<< lodepng_error_text(error)<< std::endl;

                //prepare the data
                unsigned char* alphaChannel = new unsigned char[in.size()/4];
                divideAlphaChannel(input_h+k*imgBytes, alphaChannel, in);

                // Kernel launcher
                if(j==0 && k>0)
                    cudaDeviceSynchronize();
                    //cudaStreamSynchronize(stream[j]); 
                streamBlurBoxFilter( input_h+k*imgBytes, output_h+k*imgBytes, input_d+strOffs, output_d+strOffs, width, height, stream[j] );

                //output the data
                out = rebuildAlphaChannel(output_h+k*imgBytes, alphaChannel,  imgBytes);
                /*std::string s(output_path);

                std::string name = fname.substr(0, );
                std::string ext = fname.substr(1, s.find("."));
                //s.append(fname.c_str());
                s.append(name.c_str());
                s.append(std::to_string(k));
                s.append(ext.c_str());
                //s.append(fname.c_str());
                //s.append(std::to_string(k));
                const char * out_fname=s.c_str();*/

                std::string s = getOutFullFileName(output_path, fname, k).c_str();
                const char *out_fname = s.c_str();


                error = lodepng::encode(out_fname, out, width, height);
                if(error) 
                    std::cout<<"encoder error "<< error <<": "<< lodepng_error_text(error) <<std::endl;

                ++k;
                #ifndef MEASURES
                    printImageInfos(width, height);
                #endif
                in.clear();
                out.clear();
                delete[] alphaChannel;
            }              
        }

        msTot = endEvent(&startEvent, &stopEvent);
        end = std::chrono::system_clock::now();
        millis = end - start;

        #ifdef MEASURES          
            printImgMeasures(label, msTot, millis.count(), k, devId);     
        #endif  
        streamDestroy(stream,nStreams);
        cudaFreeHost(input_h);
        cudaFreeHost(output_h);
        
    }

    cudaFree(input_d);
    cudaFree(output_d);




#endif




/*** BLURGAUSS ***/
/*#elif BLURGAUSS
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
#endif*/

    
    #ifndef MEASURES 
        printTotalTimes(msTot,  millis.count() );
    #endif
    cudaDeviceReset();
    return 0;
}