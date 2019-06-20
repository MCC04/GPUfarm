#include <math.h>
#include <algorithm>
#include <imageMatrix.h>


#define HIGH 500.0f
#define LOW -500.0f

/*************
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

void getGaussian(float* ker,int dim, float sigma)
{
    float sum=0.0;
    int i,j;
    float sigma2 = sigma*sigma;
    for (i=0 ; i<dim ; i++) {
        for (j=0 ; j<dim ; j++) {
            int i2 = i*i;
            int j2 = j*i;
            int r = std::sqrt(i2+j2);
            //float val = exp((float)(-(i2+j2))/(2*sigma2))/(2*M_PI*sigma2);
            float val = exp((float)(-(r*r))/(2*sigma2))/(2*M_PI*sigma2);

            setMatrixVal<float>(ker,i,j,dim, val);
            sum += val;
        }
    }

    for (i=0 ; i<dim ; i++) 
        for (j=0 ; j<dim ; j++) {
            float val=getMatrixVal<float>(ker,i,j,dim)/sum;
            setMatrixVal<float>(ker,i,j,dim, val);
        }
}


/**********
* KERNELS *
***********/

/**** MATMUL ****/
__global__ void matMulKernel(float* A, float* B, float* C, int m, int k, int n, int chunk) {   
    int ROW = blockIdx.x*blockDim.x+threadIdx.x;
    int COL = blockIdx.y*blockDim.y+threadIdx.y;
 
    if (ROW<m && COL<n) {
        int sizeA = m*k;
        int sizeB = k*n;
        int sizeC = m*n;
        float tmpSum = 0.0f;
        int offsA = 0, offsB = 0, offsC = 0;
        
        for (int s=0; s<chunk; ++s)
        {
            offsA = s*sizeA;
            offsB = s*sizeB;
            offsC = s*sizeC;
            tmpSum = 0.0f;
        
            for (int i = 0; i < k; ++i) {
                tmpSum += A[offsA+(ROW*k)+i] * B[offsB+(i*n)+COL];
            }        
            C[offsC+(ROW*n)+COL] = tmpSum;
        }
    }
    return ;
}

/**** GRID-STRIDE MATMUL ****/
__global__ void matMulGridStride(float* A, float* B, float* C, int m, int k, int n, int chunk) {
    int ROW = blockIdx.x*blockDim.x+threadIdx.x;
    int COL = blockIdx.y*blockDim.y+threadIdx.y;

    int Rstride = blockDim.x*gridDim.x;
    int Cstride = blockDim.y*gridDim.y;    

    float tmpSum = 0.0f;
    int offsA = 0, offsB = 0, offsC = 0;
    for (int s=0; s<chunk; ++s)
    {
        offsA = s*m*k;
        offsB = s*k*n;
        offsC = s*m*n;

        for (int r=ROW; r<m; r+=Rstride) {
            for (int c=COL; c<n; c+=Cstride) {        
               tmpSum=0;
                for (int i = 0; i <k; ++i) {
                    tmpSum += A[offsA+(r*k)+i] * B[offsB+(i*n)+c];
                }
                C[offsC+(r*n)+c] = tmpSum;
            }           
        }
    }    
    return ;
}

/**** SQUARE MATMUL ****/
__global__ void squareMatMulKernel(float* A, float* B, float* C, int N, int chunk) {

    int ROW = blockIdx.x*blockDim.x+threadIdx.x;
    int COL = blockIdx.y*blockDim.y+threadIdx.y;
 
    if (ROW<N && COL<N) {
        int size=N*N;
        float tmpSum=0.0f;        
        for (int s=0; s<chunk; ++s)
        {
            int offs = s*size;
            tmpSum = 0.0f;        
            for (int i = 0; i < N; ++i) {
                tmpSum += A[offs+(ROW*N)+i] * B[offs+(i*N)+COL];
            }        
            C[offs+(ROW*N)+COL] = tmpSum;
        }
    }
    return ;
}

/**** GRID-STRIDE SQUARE MATMUL ****/
__global__ void squareMatMulGridStrideKer(float* A, float* B, float* C, int N, int chunk) {

    int ROW = blockIdx.x*blockDim.x+threadIdx.x;
    int COL = blockIdx.y*blockDim.y+threadIdx.y;

    int Rstride = blockDim.x*gridDim.x;
    int Cstride = blockDim.y*gridDim.y;    

    float tmpSum = 0.0f;
    int offs = 0;
    for (int s=0; s<chunk; ++s)
    {
        offs = s*N*N;
        for (int k=ROW; k<N; k+=Rstride) {
            for (int j=COL; j<N; j+=Cstride) {        
               tmpSum=0;
                for (int i = 0; i < N; i++) {
                    tmpSum += A[offs+(k*N)+i] * B[offs+(i*N)+j];
                }
                C[offs+(k*N)+j] = tmpSum;
            }               
        }
    }    
    return ;
}

/**** BLURBOX ****/
__global__ void blurBoxFilterKer(unsigned char* input_image, unsigned char* output_image, int width, int height) {

    const unsigned int offset = blockIdx.x*blockDim.x+threadIdx.x;
    int dim = width*height*3;
    if(offset<dim){
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
    return;
}

/**** GRID-STRIDE BLUR BOX ****/
__global__ void blurBoxGridStride(unsigned char* input_image, unsigned char* output_image, int width, int height) {

    const unsigned int offset = blockIdx.x*blockDim.x + threadIdx.x;
    const unsigned int stride = gridDim.x * blockDim.x;
    int fsize = 5; // Filter size

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


/**** GAUSSIAN BLUR ****/
__global__ void gaussianBlurKer (const unsigned char* const inputChannel, unsigned char* outputChannel,
                                int numRows, int numCols, const float* filter, const int filterWidth)
{
    /*
     int x = blockDim.x * blockIdx.x + threadIdx.x;
    int y = blockDim.y * blockIdx.y + threadIdx.y;
    //if (x >= numCols || y >= numRows)
    //    return;
    if (x < numRows && y < numCols){
        int idx = x*numCols+y;
        float blur = 0.0f;
        for (int i = 0; i < filterWidth; ++i) {
            for (int j = 0; j < filterWidth; ++j) {
                int p_x = x+i-filterWidth/2;
                int p_y = y+j-filterWidth/2;
                p_x = min(max(p_x,0), numRows-1);
                p_y = min(max(p_y,0), numCols-1);
                float filter_value = filter[ i*filterWidth+j ];
                blur += filter_value*static_cast<float>(inputChannel[ p_x*numCols+p_y ]);
            }
        }
        outputChannel[idx] = blur;
    }
    return ;
    */



    int r = blockDim.x * blockIdx.x + threadIdx.x;
    int c = blockDim.y * blockIdx.y + threadIdx.y;
    //if (x >= numCols || y >= numRows)
    //    return;
    if (r < numCols && c < numRows){
        int idx = c*numCols+r;
        float blur = 0.0f;
        for (int fr = 0; fr < filterWidth; ++fr) {
            for (int fc = 0; fc < filterWidth; ++fc) {
                int p_x = r+fr-filterWidth/2;
                int p_y = c+fc-filterWidth/2;
                p_x = min(max(p_x,0), numCols-1);
                p_y = min(max(p_y,0), numRows-1);
                float filter_value = filter[ fc*filterWidth+fr ];
                blur += filter_value*static_cast<float>(inputChannel[ p_y*numCols+p_x ]);
            }
        }
       // outputChannel[idx] = static_cast<unsigned short>(blur);
       outputChannel[idx] = blur;
    }
    return ;
}

/**** GRID-STRIDE GAUSSIAN BLUR ****/
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
void newMatMulKer(float *A, float *B, float *C, float *Ad, float *Bd, float *Cd, 
        int m, int k, int n, int chunk, cudaStream_t strm)
{
    int bytesA = m*k*sizeof(float);
    int bytesB = k*n*sizeof(float);
    int bytesC = m*n*sizeof(float);

    cudaMemcpyAsync(Ad, A, bytesA*chunk, cudaMemcpyHostToDevice, strm);    
    cudaMemcpyAsync(Bd, B, bytesB*chunk, cudaMemcpyHostToDevice, strm);   

    dim3 dimBlock( BLOCK,BLOCK,1 );
    #ifdef LOWPAR
        GRIDx = 1;
        GRIDy = 1;
        dim3 dimGrid( GRIDx,GRIDy,1 ); 
        matMulGridStride<<<dimGrid, dimBlock, 0, strm>>>(Ad, Bd, Cd, m,  k,  n, chunk);
    #else
        int sizeX,sizeY;
        if (m%BLOCK == 0) sizeX = m;
        else sizeX = m+BLOCK-1;

        if (n%BLOCK == 0) sizeY = n;
        else sizeY = n+BLOCK-1;

        GRIDx = (sizeX)/BLOCK;
        GRIDy = (sizeY)/BLOCK;
        dim3 dimGrid( GRIDx,GRIDy,1 ); 
        matMulKernel<<<dimGrid, dimBlock, 0, strm>>>(Ad, Bd, Cd, m,  k,  n, chunk);
    #endif

    cudaMemcpyAsync( C, Cd, bytesC*chunk, cudaMemcpyDeviceToHost, strm);

    //cudaDeviceSynchronize();
}

/**** SQUARE MATMUL ****/
void newSquareMatMulKer(float *A, float *B, float *C, float *Ad, float *Bd, float *Cd, 
            int n, int chunk, cudaStream_t strm)
{
    int size = n*n;
    int bytesMat = size*sizeof(float);

    gpuErrchk( cudaMemcpyAsync(Ad, A, bytesMat*chunk, cudaMemcpyHostToDevice, strm) );    
    gpuErrchk( cudaMemcpyAsync(Bd, B, bytesMat*chunk, cudaMemcpyHostToDevice, strm) );   

    dim3 dimBlock( BLOCK,BLOCK,1 );
    #ifdef LOWPAR        
        GRIDx = 1;
        dim3 dimGrid( GRIDx,GRIDx,1 ); 
        squareMatMulGridStrideKer<<<dimGrid, dimBlock, 0, strm>>>(Ad, Bd, Cd, n, chunk);
    #else
        int sizeX;
        if (n%BLOCK == 0) sizeX = n;
        else sizeX = n+BLOCK-1;

        GRIDx = (sizeX)/BLOCK;
        dim3 dimGrid( GRIDx,GRIDx,1 ); 
        squareMatMulKernel<<<dimGrid, dimBlock, 0, strm>>>(Ad, Bd, Cd, n, chunk);
    #endif
    squareMatMulKernel<<<dimGrid, dimBlock, 0, strm>>>(Ad, Bd, Cd, n, chunk);

    gpuErrchk( cudaMemcpyAsync( C, Cd, bytesMat*chunk, cudaMemcpyDeviceToHost, strm) );

    //cudaDeviceSynchronize();
}
#endif

/**** BLURBOX ****/
#ifdef BLURBOX
void blurBoxFilter (unsigned char *img_in, unsigned char *img_out, unsigned char *in_d, unsigned char *out_d, 
                    int width, int height, int bytesSize, cudaStream_t strm)
{          
    dim3 blockDims( BLOCK,1,1 );
    gpuErrchk( cudaMemcpyAsync(in_d,img_in, bytesSize, cudaMemcpyHostToDevice, strm) );  
    #ifdef LOWPAR   
        GRIDx = 1;     
        dim3 gridDims( GRIDx,1,1 ); 
        blurBoxGridStride<<<gridDims, blockDims, 0, strm>>>(in_d, out_d, width, height); 
    #else
        GRIDx = (unsigned int)((bytesSize+BLOCK-1)/blockDims.x);
        dim3 gridDims( GRIDx,1,1 );
        blurBoxFilterKer<<<gridDims, blockDims, 0, strm>>>(in_d, out_d, width, height); 
    #endif
    gpuErrchk( cudaMemcpyAsync( img_out, out_d, bytesSize, cudaMemcpyDeviceToHost, strm) );
    cudaDeviceSynchronize();

}
#endif

/**** BLURGAUSS ****/
#ifdef BLURGAUSS
void blurGaussianfilter (unsigned char *img_in, unsigned char *img_out, unsigned char *in_d, unsigned char *out_d, 
                        float *ker_d, int width, int height, int bytesSize, int kerdim, cudaStream_t strm)
{    
    dim3 blockDims( BLOCK,BLOCK,1 );
    gpuErrchk( cudaMemcpyAsync(in_d, img_in, bytesSize, cudaMemcpyHostToDevice, strm) );    
    #ifdef LOWPAR        
        dim3 gridDims( 1,1,1 );
        gaussianBlurGridStride<<<gridDims, blockDims, 0, strm>>>(in_d, out_d, height, width, ker_d, kerdim);
   #else
        dim3 gridDims(((width*3)+blockDims.x-1)/blockDims.x, ((height*3)+blockDims.y-1)/blockDims.y, 1 ); 
        gaussianBlurKer<<<gridDims, blockDims, 0, strm>>>(in_d, out_d, height, width, ker_d, kerdim);
    #endif
    gpuErrchk( cudaMemcpyAsync( img_out, out_d, bytesSize, cudaMemcpyDeviceToHost, strm) );
    cudaDeviceSynchronize();
}
#endif