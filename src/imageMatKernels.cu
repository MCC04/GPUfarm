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
{ return mat[row*width + col]; }

template<typename T> void setMatrixVal(T *mat, int row, int col, int width, T val)
{ mat[row*width + col] = val; }

void randomMatrix(const int m, int n,float *mat){
    for(int r = 0; r<m; ++r)
        for(int c = 0; c<n; ++c){
            float val=LOW + (float) std::rand() * (HIGH-LOW) / RAND_MAX;
            setMatrixVal(mat, r, c, n, val);
        }     
}

float* getGaussian(int dim, float sigma)
{
    float *ker=new float[dim*dim];
    float sum=0.0;
    int i,j;

    for (i=0 ; i<dim ; i++) {
        for (j=0 ; j<dim ; j++) {
            int i2 = i*i;
            int j2 = j*i;
            float sigma2 = sigma*sigma;
            float val = exp((float)(-(i2+j2))/(2*sigma2))/(2*M_PI*sigma2);
            setMatrixVal<float>(ker,i,j,dim, val);
            sum += val;
        }
    }

    for (i=0 ; i<dim ; i++) 
        for (j=0 ; j<dim ; j++) {
            float val=getMatrixVal<float>(ker,i,j,dim)/sum;
            setMatrixVal<float>(ker,i,j,dim, val);
        }

    return ker;
}

/************
** KERNELS **
*************/
__global__ void matMulKernel(float* A, float* B, float* C, int m, int k, int n, int chunk)
{
    int row = blockIdx.y*blockDim.y+threadIdx.y;
    int col = blockIdx.x*blockDim.x+threadIdx.x;

    //devo cercare di farlo funzionare con l'approccio tc non sia necessario usare un for (s<chunk)
    for (int s = 0; s < chunk; ++s) //ma va bene così??? 
    {
        float *tmpA = &A[s*m*k];
        float *tmpB = &B[s*k*n];
        float *tmpC = &C[s*m*n];
        float tmpSum = 0;

        if(row<m && col<n) {
           // float sum = 0;
            for(int j=0;j<k;j++) {
                tmpSum += tmpA[row*k+j] * tmpB[j*n+col];
            }
            tmpC[row*n+col] = tmpSum;
        }
    }
    return ;
}

__global__ void matMulGridStride(float* A, float* B, float* C, int m, int k, int n, int chunk)//(int M, int N, float *x_d, int *myclocks, int offset){    
{
    int indexRow = blockIdx.x*blockDim.x + threadIdx.x;
    int strideRow = blockDim.x*gridDim.x;

    int indexCol = blockIdx.y*blockDim.y + threadIdx.y;
    int strideCol = blockDim.y*gridDim.y;

    /* A [M x K]
    *  B [K x N]
    *  C [M x N]
    */
    for (int s = 0; s < chunk; ++s)
    {
        float *tmpA = &A[s*m*k];
        float *tmpB = &B[s*k*n];
        float *tmpC = &C[s*m*n];
        float tmpSum = 0;

        for (int i = indexRow; i < m; i += strideRow) //M
        {
            for (int j = indexCol; j < n; j += strideCol) //N
            {
                //float sum = 0;
                for(int l=0; l<k; l++) //K
                {
                    tmpSum += tmpA[i*k + l] * tmpB[l*n + j];
                }
                tmpC[i*n + j] = tmpSum;
            }
        }
    }
    return ;
}

__global__ void squareMatMulKernel(float* A, float* B, float* C, int N, int chunk) {

   int ROW = blockIdx.y*blockDim.y+threadIdx.y;
        int COL = blockIdx.x*blockDim.x+threadIdx.x;
 
    if (ROW < N && COL < N) {

    for (int s = 0; s < chunk; s++)
    {
        float *tmpA = &A[s*N*N];
        float *tmpB = &B[s*N*N];
        float *tmpC = &C[s*N*N];
        float tmpSum = 0;
    
            for (int i = 0; i < N; i++) {
                tmpSum += tmpA[ROW * N + i] * tmpB[i * N + COL];
            }
       
        
        tmpC[ROW * N + COL] = tmpSum;
        __syncthreads();
    }


 }

/*

    int ROW = blockIdx.y*blockDim.y+threadIdx.y;
    int COL = blockIdx.x*blockDim.x+threadIdx.x;

    float tmpSum = 0;
    if (ROW < N && COL < N) {
        for (int i = 0; i < N; i++) {
            tmpSum += A[ROW * N + i] * B[i * N + COL];
        }
        C[ROW * N + COL] = tmpSum;
        
    }*/

    return ;
}

__global__ void squareMatMulGridStrideKer(float* A, float* B, float* C, int N, int chunk) {

/*    int ROW = blockIdx.y*blockDim.y+threadIdx.y;
    int Rstride = blockDim.y*gridDim.y;

    int COL = blockIdx.x*blockDim.x+threadIdx.x;
    int Cstride = blockDim.x*gridDim.x;

    

    for (int s = 0; s < chunk; s++)
    {
        float *tmpA = &A[s*N*N];
        float *tmpB = &B[s*N*N];
        float *tmpC = &C[s*N*N];
        float tmpSum = 0;

      for (int j = COL; j < N; j+=Cstride) { 
           for (int i = ROW; i < N; i+=Rstride) {

            //// if (ROW < N && COL < N) {
            //// each thread computes one element of the block sub-matrix
            ////for (int i = 0; i < N; i++) {
            
                //tmpSum += A[i * N + j] * B[j * N + i];
                tmpC[j * N + i] += tmpA[i * N + j] * tmpB[j * N + i];
            }
            ////}
            //tmpC[i * N + COL] = tmpSum;
            //tmpC[i * N + COL] = tmpSum;
        }
        //tmpC[ROW * N + COL] = tmpSum;
    }
*/
    

    int ROW = blockIdx.y*blockDim.y+threadIdx.y;
    int COL = blockIdx.x*blockDim.x+threadIdx.x;

    int Rstride = blockDim.y*gridDim.y;
    int Cstride = blockDim.x*gridDim.x;



    //float tmpSum = 0;

    for (int s = 0; s < chunk; s++)
    {
        float *tmpA = &A[s*N*N];
        float *tmpB = &B[s*N*N];
        float *tmpC = &C[s*N*N];
        float tmpSum = 0;

        //if (ROW < N && COL < N) {
        for (int j = COL; j < N; j+=Cstride) { 
            
           for (int k = ROW; k < N; k+=Rstride) {
               tmpSum=0;
                for (int i = 0; i < N; i++) {
                    tmpSum += tmpA[k * N + i] * tmpB[i * N + j];
                }
                tmpC[k * N + j] = tmpSum;
            }   
            
        }

    }

    
    return ;
}




__global__ void blurBoxFilterKer(unsigned char* input_image, unsigned char* output_image, int width, int height) {

    const unsigned int offset = blockIdx.x*blockDim.x+threadIdx.x;
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

    return;
}

__global__ void gaussianBlurKer (const unsigned char* const inputChannel, unsigned char* outputChannel,
                                int numRows, int numCols, const float* filter, const int filterWidth)
{
    int x = blockDim.x * blockIdx.x + threadIdx.x;
    int y = blockDim.y * blockIdx.y + threadIdx.y;
    //if (x >= numCols || y >= numRows)
    //    return;
    if (x <>=> numCols && y < numRows){
        int idx = y * numCols + x;
        float blur = 0.0f;
        for (int i = 0; i < filterWidth; i++) {
            for (int j = 0; j < filterWidth; j++) {
                int p_x = x+i-filterWidth/2;
                int p_y = y+j-filterWidth/2;
                p_x = min(max(p_x,0), numCols-1);
                p_y = min(max(p_y,0), numRows-1);
                float filter_value = filter[ i*filterWidth+j ];
                blur += filter_value*static_cast<float>(inputChannel[ p_y*numCols+p_x ]);
            }
        }
        outputChannel[idx] = blur;
    }
    return ;
}



__global__ void blurBoxGridStride(unsigned char* input_image, unsigned char* output_image, int width, int height) {

    const unsigned int offset = blockIdx.x*blockDim.x + threadIdx.x;
    const unsigned int stride = gridDim.x * blockDim.x;

    //int x = offset % width;
    //int y = (offset-x)/width;
    int fsize = 5; // Filter size
    //if(offset < width*height) {

    for(int i=offset; i<width*height; i+=stride)
    {    
        int x = offset % width;
        int y = (offset-x)/width;

        float output_red = 0;
        float output_green = 0;
        float output_blue = 0;
        int hits = 0;
        for(int ox = -fsize; ox < fsize+1; ++ox) {
            for(int oy = -fsize; oy < fsize+1; ++oy) {
                if((x+ox) > -1 && (x+ox) < width && (y+oy) > -1 && (y+oy) < height) {
                    const int currentoffset = ( i +ox+oy*width)*3;
                    output_red += input_image[currentoffset]; 
                    output_green += input_image[currentoffset+1];
                    output_blue += input_image[currentoffset+2];
                    hits++;
                }
            }
        }
        output_image[i *3] = output_red/hits;
        output_image[i *3+1] = output_green/hits;
        output_image[i *3+2] = output_blue/hits;
    }
    return ;
}

__global__ void gaussianBlurGridStride(
 const unsigned char* const inputChannel,
unsigned char* outputChannel,
int numRows, int numCols,
const float* filter, const int filterWidth)
{
    const unsigned int indexX = blockDim.x * blockIdx.x + threadIdx.x;
    const unsigned int indexY = blockDim.y * blockIdx.y + threadIdx.y;

    const unsigned int strideX = blockDim.x * gridDim.x;
    const unsigned int strideY = blockDim.y * gridDim.y;

    //if (x >= numCols || y >= numRows)
      //  return;

    for(int k=indexX; k<numCols; k+=strideX)
    {
        for(int l=indexY; l<numRows; l+=strideY)
        {
            int idx = l * numCols + k;
            float blur = 0.0f;
            for (int i = 0; i < filterWidth; i++) {
                for (int j = 0; j < filterWidth; j++) {
                    int p_x = k + i - filterWidth/2;
                    int p_y = l + j - filterWidth/2;
                    p_x = min(max(p_x, 0), numCols - 1);
                    p_y = min(max(p_y, 0), numRows - 1);
                    float filter_value = filter[i * filterWidth + j];
                    blur += filter_value *
                    static_cast<float>(inputChannel[p_y * numCols + p_x]);
                }
            }
            outputChannel[idx] = blur;
        }
    }
    return ;
}


/*******************
**KERNEL LAUNCHERS**
********************/

/**** NON SQUARE MATMUL ****/
#ifdef MATMUL
float newMatMulKer(float *A, float *B, float *C, float *Ad, float *Bd, float *Cd, 
        int m, int k, int n, int chunk, cudaStream_t strm, cudaEvent_t start, cudaEvent_t stop)
{
    float ms=0;
    int bytesA = m*k*sizeof(float);
    int bytesB = k*n*sizeof(float);
    int bytesC = m*n*sizeof(float);

    dim3 dimBlock(BLOCK,BLOCK,1);
    dim3 dimGrid(GRIDx, GRIDy,1); 

    cudaMemcpyAsync(Ad, A, bytesA*chunk, cudaMemcpyHostToDevice, strm);    
    cudaMemcpyAsync(Bd, B, bytesB*chunk, cudaMemcpyHostToDevice, strm);   

    #ifdef LOWPAR
        matMulGridStride<<<dimGrid, dimBlock, 0, strm>>>(Ad, Bd, Cd, m,  k,  n, chunk);
    #else
        matMulKernel<<<dimGrid, dimBlock, 0, strm>>>(Ad, Bd, Cd, m,  k,  n, chunk);
    #endif

    cudaMemcpyAsync( C, Cd, bytesC*chunk, cudaMemcpyDeviceToHost, strm);

    return ms;
}

/**** SQUARE MATMUL ****/
float newSquareMatMulKer(float *A, float *B, float *C, float *Ad, float *Bd, float *Cd, 
            int n, int chunk, cudaStream_t strm, cudaEvent_t start, cudaEvent_t stop)
{
    float ms=0;
    int size=n*n;
    int bytesMat=size*sizeof(float);

    dim3 dimBlock(BLOCK,BLOCK,1);
    dim3 dimGrid(GRIDx, GRIDy,1); 

    checkCuda( cudaMemcpyAsync(Ad, A, bytesMat*chunk, cudaMemcpyHostToDevice, strm) );    
    checkCuda( cudaMemcpyAsync(Bd, B, bytesMat*chunk, cudaMemcpyHostToDevice, strm) );   

    #ifdef LOWPAR
        squareMatMulGridStrideKer<<<dimGrid, dimBlock, 0, strm>>>(Ad, Bd, Cd, n, chunk);
    #else
        squareMatMulKernel<<<dimGrid, dimBlock, 0, strm>>>(Ad, Bd, Cd, n, chunk);
    #endif

    checkCuda( cudaMemcpyAsync( C, Cd, bytesMat*chunk, cudaMemcpyDeviceToHost, strm) );
    
    return ms;
}
#endif


/**** BLURBOX ****/
#ifdef BLURBOX
float blurBoxFilter (
    unsigned char *img_in, unsigned char *img_out,
    int width, int height,
    cudaStream_t strm, cudaEvent_t start, cudaEvent_t stop)
{    
    float ms=0;
    //int bytes=width*height*3*sizeof(unsigned char);
       
    #ifdef LOWPAR
        dim3 blockDims(2,1,1);
        dim3 gridDims(1,1,1); 
    #else
        dim3 blockDims(BLOCK,1,1);
        dim3 gridDims((unsigned int) ceil((double)(width*height*3/blockDims.x)), 1, 1 );
    #endif
    checkCuda( cudaEventRecord(start,0) ); 

    #ifdef LOWPAR
        blurBoxGridStride<<<gridDims, blockDims, 0, strm>>>(img_in, img_out, width, height); 
    #else
        blurBoxFilterKer<<<gridDims, blockDims, 0, strm>>>(img_in, img_out, width, height); 
    #endif

    checkCuda( cudaEventRecord(stop, 0) );
    checkCuda( cudaEventSynchronize(stop) );
    checkCuda( cudaEventElapsedTime(&ms, start, stop) );
 
    return ms;
}
#endif

/**** BLURGAUSS ****/
#ifdef BLURGAUSS
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
        dim3 blockDims(2,2,1);
        dim3 gridDims(1,1, 1 );
    #else
        dim3 blockDims(BLOCK,BLOCK,1);        
        dim3 gridDims((width*3)/blockDims.x, (height*3)/blockDims.y, 1 ); //dim3 gridDims((unsigned int) ceil((double)(bytes/blockDims.x)), 1, 1 );
    #endif
    checkCuda( cudaEventRecord(start,0) ); 

    #ifdef LOWPAR
        gaussianBlurGridStride<<<gridDims, blockDims, 0, strm>>>(img_in, img_out, height, width, ker, kerdim);
    #else
        gaussianBlurKer<<<gridDims, blockDims, 0, strm>>>(img_in, img_out, height, width, ker, kerdim);
    #endif

    checkCuda( cudaEventRecord(stop, 0) );
    checkCuda( cudaEventSynchronize(stop) );
    checkCuda( cudaEventElapsedTime(&ms, start, stop) );
 
    return ms;
}
#endif