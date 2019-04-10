//#include <cuda_runtime.h>
#include <iostream>
#include <math.h>
#include <stdlib.h>
 
#include <cstdlib>
#include <algorithm>
#include <ctime>
#include <vector>
#include <future>
#include <iterator>
//#include <cudaUtils.h>
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

/*float getMatrixVal(float *mat, int row, int col, int width)
{
    return mat[row + col*width];
}

void setMatrixVal(float *mat, int row, int col, int width, float val)
{   
    mat[row + col*width] = val;
}

/*void randomMatrix(const int m, int n,float *mat){
    #ifndef MEASURES
        std::cout<< "MATRIX M: "<<std::endl;  
    #endif

    for(int r = 0; r<m; ++r){
        for(int c = 0; c<n; ++c){
            float val=LOW + (float) std::rand() * (HIGH-LOW) / RAND_MAX;
            setMatrixVal(mat, r, c, n, val);

            #ifndef MEASURES
                std::cout<< getMatrixVal(mat,r,c,n) << ", ";              
            #endif
        }
        #ifndef MEASURES
            std::cout<< std::endl;  
        #endif
    }       
}

int* getGaussian(int height, int width, double sigma)
{
    //Matrix kernel(height, Array(width));
    double sum=0.0;
    int i,j;

    for (i=0 ; i<height ; i++) {
        for (j=0 ; j<width ; j++) {
            kernel[i][j] = exp(-(i*i+j*j)/(2*sigma*sigma))/(2*M_PI*sigma*sigma);
            sum += kernel[i][j];
        }
    }

    for (i=0 ; i<height ; i++) {
        for (j=0 ; j<width ; j++) {
            kernel[i][j] /= sum;
        }
    }

    return kernel;
}*/

/*********
**KERNELS*
**********/
__global__ void emptyKernel(){ return; }

__global__ void cosKernel(int M, int N, float *x_d, int *myclocks, int offset){    
    int idx = offset+blockIdx.x*blockDim.x + threadIdx.x; 
   
    clock_t start =clock();

    for(int j=0;j<M;j+=1)
        x_d[idx]=cosf(x_d[idx]);  

    clock_t end=clock();

    if (threadIdx.x == 0) myclocks[blockIdx.x+(offset/blockDim.x)]=(int)(end-start);
    return ;
}

//M = iterations; N = size
__global__ void cosGridStride(int M, int N, float *x_d, int offset, int *myclocks){    
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

/*__global__ void matMulKernel(float* Ad, float* Bd, float* Cd, int m, int n, int k)
{
    int row = blockIdx.y*blockDim.y+threadIdx.y;
    int col = blockIdx.x*blockDim.x+threadIdx.x;

    if(row<m && col<n) {
        float sum = 0;
        for(int j=0;j<k;j++) {
            sum += Ad[row*k+j] * Bd[j*n+col];
        }
        Cd[row*n+col] = sum;
    }
}

__global__
void blurKernel(unsigned char* input_image, unsigned char* output_image, int width, int height) {

    const unsigned int offset = blockIdx.x*blockDim.x + threadIdx.x;
    int x = offset % width;
    int y = (offset-x)/width;
    int fsize = 5; // Filter size
    if(offset < width*height) {

        float output_red = 0;
        float output_green = 0;
        float output_blue = 0;
        int hits = 0;
        for(int ox = -fsize; ox < fsize+1; ++ox) {
            for(int oy = -fsize; oy < fsize+1; ++oy) {
                if((x+ox) > -1 && (x+ox) < width && (y+oy) > -1 && (y+oy) < height) {
                    const int currentoffset = (offset+ox+oy*width)*3;
                    output_red += input_image[currentoffset]; 
                    output_green += input_image[currentoffset+1];
                    output_blue += input_image[currentoffset+2];
                    hits++;
                }
            }
        }
        output_image[offset*3] = output_red/hits;
        output_image[offset*3+1] = output_green/hits;
        output_image[offset*3+2] = output_blue/hits;
        }
}*/


//KERNEL LAUNCERS
float emptyKer(){
    float ms=0;
    cudaEvent_t startEvent, stopEvent;
    checkCuda( cudaEventCreate(&startEvent) );
    checkCuda( cudaEventCreate(&stopEvent) );   

    checkCuda( cudaEventRecord(startEvent,0) );
    
    emptyKernel<<<GRID, BLOCK>>>();

    checkCuda( cudaEventRecord(stopEvent, 0) );
    checkCuda( cudaEventSynchronize(stopEvent) );
    checkCuda( cudaEventElapsedTime(ms, startEvent, stopEvent) );

    return ms;
    
}

void cosKer(std::vector<my_struct> &getDatas,int bytesSize )
{
    std::vector<std::future<my_struct>> futures;
    int *clocks_d;
    float *x_d;    

    cudaEvent_t startEvent, stopEvent;
    checkCuda( cudaEventCreate(&startEvent) );
    checkCuda( cudaEventCreate(&stopEvent) );    

    checkCuda(cudaMalloc(&x_d, bytesSize)); 
    checkCuda(cudaMalloc(&clocks_d, GRID*sizeof(int)));

    for(int i = 0; i < K_exec; ++i) {
        futures.push_back (std::async(std::launch::deferred,
            [&]() { 
                my_struct _xs;
                _xs.clocks=new int[GRID];
                _xs.x_vect=new float[N_size];
                randomArray(_xs.x_vect, N_size);

                checkCuda( cudaEventRecord(startEvent,0) );

                checkCuda(cudaMemcpy(x_d, _xs.x_vect, bytesSize, cudaMemcpyHostToDevice)); 

                #ifdef STRIDE
                    cosGridStride<<<GRID, BLOCK>>>(M_iter, N_size, x_d, 0, clocks_d);
                #else
                    cosKernel<<<GRID, BLOCK>>>(M_iter, N_size, x_d,clocks_d, 0);
                #endif
                              
                checkCuda(cudaMemcpy( _xs.x_vect, x_d, bytesSize, cudaMemcpyDeviceToHost));
                checkCuda(cudaMemcpy(_xs.clocks, clocks_d, GRID*sizeof(int), cudaMemcpyDeviceToHost));

                checkCuda( cudaEventRecord(stopEvent, 0) );
                checkCuda( cudaEventSynchronize(stopEvent) );
                checkCuda( cudaEventElapsedTime(&_xs.eventTime, startEvent, stopEvent) );

                return _xs;
            }));          
    }
    for(auto &e : futures) 
        getDatas.push_back(e.get());
}



void cosKerStream(
    int m, int n,
    float *x, //float *cosx,  
    int *clocks, 
    int offset, cudaStream_t strm)
{
        #ifdef STRIDE
            cosGridStride<<<GRID, BLOCK, offset, strm>>>(m, n, x, clocks, offset);
        #else
            cosKernel<<<GRID, BLOCK, offset, strm>>>(m, n, x, clocks, offset);
        #endif
}




float  cosKerStream(
    cudaEvent_t start, cudaEvent_t stop,
    int m, int n,
    float *x, float *cosx,  int *clocks, 
    int offset, cudaStream_t strm)
{
    float ms;  
    randomArray(x, n);
    memcpy(cosx,x,N_size);
    checkCuda( cudaEventRecord(start,0) );

    #ifdef STRIDE
        cosGridStride<<<GRID, BLOCK, offset, strm>>>(m, n, cosx, clocks, offset);
    #else
        cosKernel<<<GRID, BLOCK, offset, strm>>>(m, n, cosx, clocks, offset);
    #endif

    checkCuda( cudaEventRecord(stop, 0) );
    checkCuda( cudaEventSynchronize(stop) );
    checkCuda( cudaEventElapsedTime(&ms, start, stop) );
     
    return ms;
}
/*
float matMulKer(
    float *Ad, float *Bd, float *Cd, 
    int m, int k, int n, 
    cudaStream_t strm, cudaEvent_t start, cudaEvent_t stop)
{

    float ms;
    #ifdef LOWPAR
        dim3 dimBlock(32,32);
        dim3 dimGrid(1,1); 
    #else
        dim3 dimBlock(BLOCK,BLOCK);
        dim3 dimGrid((m+dimBlock.x-1)/dimBlock.x, (n+dimBlock.y-1)/dimBlock.y); 
    #endif
    

    randomMatrix(m,k, Ad);
    randomMatrix(k,n, Bd); 

    checkCuda( cudaEventRecord(start,0) );

    matMulKernel<<<dimGrid, dimBlock, 0, strm>>>(Ad, Bd, Cd, m,  k,  n);

    checkCuda( cudaEventRecord(stop, 0) );
    checkCuda( cudaEventSynchronize(stop) );
    checkCuda( cudaEventElapsedTime(&ms, start, stop) );


    return ms;
}

float filter (
    unsigned char *img_in, unsigned char *img_out,
    int width, int height,
    cudaStream_t strm,
    cudaEvent_t start, cudaEvent_t stop)
{    
    float ms=0;
    int bytes=width*height*3*sizeof(unsigned char);
       
    dim3 blockDims(512,1,1);
    dim3 gridDims((unsigned int) ceil((double)(width*height*3/blockDims.x)), 1, 1 );

    checkCuda( cudaEventRecord(start,0) ); 

    cudaMallocManaged(&img_in, bytes);
    cudaMallocManaged(&img_out, bytes);

    blurKernel<<<gridDims, blockDims, 0, strm>>>(img_in, img_out, width, height); 

    checkCuda( cudaEventRecord(stop, 0) );
    checkCuda( cudaEventSynchronize(stop) );
    checkCuda( cudaEventElapsedTime(&ms, start, stop) );
 
    return ms;
}
*/