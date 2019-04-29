#include <iostream>
#include <math.h>
#include <stdlib.h>
#include <assert.h> 
#include <cstdlib>
#include <algorithm>
#include <ctime>
#include <vector>
#include <future>
#include <iterator>
#include <cudaUtils.h>
#include <imageMatrix.h>

#define HIGH 500.0f
#define LOW -500.0f

template<typename T> T getMatrixVal(T *mat, int row, int col, int width)
{
    return mat[row*width + col];
}

template<typename T> void setMatrixVal(T *mat, int row, int col, int width, T val)
{   
    mat[row*width + col] = val;
}

void randomMatrix(const int m, int n,float *mat){
    #ifndef MEASURES
        std::cout<< "MATRIX M: "<<std::endl;  
    #endif

    for(int r = 0; r<m; ++r){
        for(int c = 0; c<n; ++c){
            float val=LOW + (float) std::rand() * (HIGH-LOW) / RAND_MAX;
            setMatrixVal(mat, r, c, n, val);

            #ifndef MEASURES
                std::cout<< getMatrixVal<float>(mat,r,c,n) << ", ";              
            #endif
        }
        #ifndef MEASURES
            std::cout<< std::endl;  
        #endif
    }       
}

float* getGaussian(int dim, float sigma)
{
    float *ker=new float[dim*dim];
    float sum=0.0;
    int i,j;

    for (i=0 ; i<dim ; i++) {
        for (j=0 ; j<dim ; j++) {
            float val = exp((float)(-(i*i+j*j))/(2*sigma*sigma))
                        /(2*M_PI*sigma*sigma);
            setMatrixVal<float>(ker,i,j,dim, val);
            sum += val;
        }
    }

    for (i=0 ; i<dim ; i++) {
        for (j=0 ; j<dim ; j++) {
            float val=getMatrixVal<float>(ker,i,j,dim)/sum;
            setMatrixVal<float>(ker,i,j,dim, val);
        }
    }

    return ker;
}

/*********
**KERNELS*
**********/
__global__ void matMulKernel(float* Ad, float* Bd, float* Cd, int m, int k, int n)
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

__global__ void blurBoxFilterKer(unsigned char* input_image, unsigned char* output_image, int width, int height) {

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
}

__global__ void gaussianBlurKer(
 const unsigned char* const inputChannel,
unsigned char* outputChannel,
int numRows, int numCols,
const float* filter, const int filterWidth)
{
    int x = blockDim.x * blockIdx.x + threadIdx.x;
    int y = blockDim.y * blockIdx.y + threadIdx.y;
    if (x >= numCols || y >= numRows)
        return;
    int idx = y * numCols + x;
    float blur = 0.0f;
    for (int i = 0; i < filterWidth; i++) {
        for (int j = 0; j < filterWidth; j++) {
            int p_x = x + i - filterWidth/2;
            int p_y = y + j - filterWidth/2;
            p_x = min(max(p_x, 0), numCols - 1);
            p_y = min(max(p_y, 0), numRows - 1);
            float filter_value = filter[i * filterWidth + j];
            blur += filter_value *
            static_cast<float>(inputChannel[p_y * numCols + p_x]);
        }
    }
    outputChannel[idx] = blur;
}

float smallMatMulKer(
    float *Ad, float *Bd, float *Cd, float *C,
    int m, int k, int n, 
    cudaStream_t strm, cudaEvent_t start, cudaEvent_t stop)
{

    float ms;
    int bytesA=m*k*sizeof(float);
    int bytesB=k*n*sizeof(float);
    int bytesC=m*n*sizeof(float);
    float  *A=(float*)calloc(1,bytesA);//new float[M_iter*K_exec];
    float *B=(float*)calloc(1,bytesB);//new float[K_exec*N_size] ;

    randomMatrix(m,k, A);
    randomMatrix(k,n, B);     

    dim3 dimBlock(BLOCK,BLOCK,1);
    dim3 dimGrid(GRIDx, GRIDy,1); 

    checkCuda( cudaEventRecord(start,0) );

    cudaMemcpyAsync(Ad, A, bytesA, cudaMemcpyHostToDevice, strm);    
    cudaMemcpyAsync(Bd, B, bytesB, cudaMemcpyHostToDevice, strm);   

    matMulKernel<<<dimGrid, dimBlock, 0, strm>>>(Ad, Bd, Cd, m,  k,  n);

    cudaMemcpyAsync( C, Cd, bytesC, cudaMemcpyDeviceToHost, strm);

    checkCuda( cudaEventRecord(stop, 0) );
    checkCuda( cudaEventSynchronize(stop) );
    checkCuda( cudaEventElapsedTime(&ms, start, stop) );

    free(A);
    free(B);

    return ms;
}

//KERNEL LAUNCERS
float matMulKer(
    float *Ad, float *Bd, float *Cd, 
    int m, int k, int n, 
    cudaStream_t strm, cudaEvent_t start, cudaEvent_t stop)
{
    float ms;    

    randomMatrix(m,k, Ad);
    randomMatrix(k,n, Bd);     
    
    #ifdef LOWPAR
        dim3 dimBlock(4,4,1);
        dim3 dimGrid(1,1,1); 
    #else
        dim3 dimBlock(BLOCK,BLOCK,1);
        dim3 dimGrid(GRIDx, GRIDy,1); 
    #endif

    checkCuda( cudaEventRecord(start,0) );

    matMulKernel<<<dimGrid, dimBlock, 0, strm>>>(Ad, Bd, Cd, m,  k,  n);

    checkCuda( cudaEventRecord(stop, 0) );
    checkCuda( cudaEventSynchronize(stop) );
    checkCuda( cudaEventElapsedTime(&ms, start, stop) );

    return ms;
}

float blurBoxFilter (
    unsigned char *img_in, unsigned char *img_out,
    int width, int height,
    cudaStream_t strm, cudaEvent_t start, cudaEvent_t stop)
{    
    float ms=0;
    int bytes=width*height*3*sizeof(unsigned char);
       
    #ifdef LOWPAR
        dim3 blockDims(16,1,1);
        dim3 gridDims(1,1,1); 
    #else
        dim3 blockDims(BLOCK,1,1);
        dim3 gridDims((unsigned int) ceil((double)(width*height*3/blockDims.x)), 1, 1 );
    #endif
    checkCuda( cudaEventRecord(start,0) ); 

    blurBoxFilterKer<<<gridDims, blockDims, 0, strm>>>(img_in, img_out, width, height); 

    checkCuda( cudaEventRecord(stop, 0) );
    checkCuda( cudaEventSynchronize(stop) );
    checkCuda( cudaEventElapsedTime(&ms, start, stop) );
 
    return ms;
}


float blurGaussianfilter (
    unsigned char *img_in, unsigned char *img_out,
    int width, int height,int kerdim, float sigma,
    cudaStream_t strm,
    cudaEvent_t start, cudaEvent_t stop)
{    

    float *ker;
    int bytes=kerdim*kerdim*sizeof(unsigned char);
    float ms=0;

    checkCuda(cudaMallocManaged(&ker, bytes));
    ker=getGaussian(kerdim, sigma);        
       
    #ifdef LOWPAR
        dim3 blockDims(4,4,1);
        dim3 gridDims(1,1, 1 );
    #else
        dim3 blockDims(16,16,1);
        
        dim3 gridDims((width*3)/blockDims.x, (height*3)/blockDims.y, 1 ); //dim3 gridDims((unsigned int) ceil((double)(bytes/blockDims.x)), 1, 1 );
    #endif
    checkCuda( cudaEventRecord(start,0) ); 

    gaussianBlurKer<<<gridDims, blockDims, 0, strm>>>(
        img_in, img_out, height, width, ker, kerdim);

    checkCuda( cudaEventRecord(stop, 0) );
    checkCuda( cudaEventSynchronize(stop) );
    checkCuda( cudaEventElapsedTime(&ms, start, stop) );
 
    return ms;
}