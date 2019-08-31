#include <math.h>
#include <algorithm>
#include <imageMatrix.h>


#define HIGH 500.0f
#define LOW -500.0f

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
        int sizeX,sizeY;
        if (m%BLOCK == 0) sizeX = m;
        else sizeX = m+BLOCK-1;

        if (n%BLOCK == 0) sizeY = n;
        else sizeY = n+BLOCK-1;

        GRIDx = (sizeX)/BLOCK;
        GRIDy = (sizeY)/BLOCK;
    #endif
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


/* ******* *
 * KERNELS *
 * ******* */

/**** MATMUL ****/
__global__ void matMulKernel(float* A, float* B, float* C, int m, int k, int n) {   
    int ROW = blockIdx.x*blockDim.x+threadIdx.x;
    int COL = blockIdx.y*blockDim.y+threadIdx.y;
 
    if (ROW<m && COL<n) {
        float tmpSum = 0.0f;        
        for (int i = 0; i < k; ++i) {
            tmpSum += A[(ROW*k)+i] * B[(i*n)+COL];
        }        
        C[(ROW*n)+COL] = tmpSum;
    }
    return ;
}

/**** SQUARE MATMUL ****/
__global__ void squareMatMulKernel(float* A, float* B, float* C, int N) {
    int COL = blockIdx.x*blockDim.x+threadIdx.x;
    int ROW = blockIdx.y*blockDim.y+threadIdx.y;
 
    if (ROW<N && COL<N) {
        float tmpSum=0.0f;        

        for (int i = 0; i < N; ++i) {
            tmpSum += A[(ROW*N)+i] * B[(i*N)+COL];
        }        
        C[(ROW*N)+COL] = tmpSum;        
    }
    return ;
}

#define TILE_WIDTH 16
/***** SHARED MATMUL *****/
__global__ void sharedMatMulKernel(float *A, float *B, float *C, int size)
{
    //const int blockSize = blockDim.x;
    // Block index
    int bx = blockIdx.x;
    int by = blockIdx.y;

    // Thread index
    int tx = threadIdx.x;
    int ty = threadIdx.y;

    // Index of the first sub-matrix of A processed by the block
    int aBegin = size * TILE_WIDTH * by;

    // Index of the last sub-matrix of A processed by the block
    int aEnd = aBegin + size - 1;

    // Step size used to iterate through the sub-matrices of A
    int aStep = TILE_WIDTH;

    // Index of the first sub-matrix of B processed by the block
    int bBegin = TILE_WIDTH * bx;

    // Step size used to iterate through the sub-matrices of B
    int bStep = TILE_WIDTH * size;

    // The element of the block sub-matrix that is computed by the thread
    float Csub = 0;



    // Loop over all the sub-matrices of A and B required to compute the block sub-matrix

    for (int a = aBegin, b = bBegin; a <= aEnd; a += aStep, b += bStep)
    {
        // Shared memory for the sub-matrices of A and B
        __shared__ float As[TILE_WIDTH][TILE_WIDTH];
        __shared__ float Bs[TILE_WIDTH][TILE_WIDTH];


        // Load the matrices from global memory to shared memory, each thread loads one element of each matrix
        As[ty][tx] = A[a + size * ty + tx];
        Bs[ty][tx] = B[b + size * ty + tx];

        // Synchronize to make sure the matrices are loaded
        __syncthreads();

        #pragma unroll
        // Multiply the two matrices together, each thread computes one element of the block sub-matrix
        for (int k = 0; k < TILE_WIDTH; ++k) 
            Csub += As[ty][k] * Bs[k][tx];


        // Synchronize to make sure that the preceding computation is done before loading two new sub-matrices of A and B in the next iteration
        __syncthreads();
    }

    // Write the block sub-matrix to global memory, each thread writes one element
    int c = size * TILE_WIDTH * by + TILE_WIDTH * bx;
    C[c + size * ty + tx] = Csub;
}







/**** GRID-STRIDE SQUARE MATMUL ****/
/* __global__ void squareMatMulGridStrideKer(float* A, float* B, float* C, int N) {

    int ROW = blockIdx.x*blockDim.x+threadIdx.x;
    int COL = blockIdx.y*blockDim.y+threadIdx.y;

    int Rstride = blockDim.x*gridDim.x;
    int Cstride = blockDim.y*gridDim.y;    

    float tmpSum = 0.0f;

    for (int k=ROW; k<N; k+=Rstride) {
        for (int j=COL; j<N; j+=Cstride) {        
            tmpSum=0;
            for (int i = 0; i < N; i++) {
                tmpSum += A[(k*N)+i] * B[(i*N)+j];
            }
            C[(k*N)+j] = tmpSum;
        }               
    }
  
    return ;















 //const int blockSize = blockDim.x;
    // Block index
    int bx = blockIdx.x;
    int by = blockIdx.y;

    // Thread index
    int tx = threadIdx.x;
    int ty = threadIdx.y;

    // Index of the first sub-matrix of A processed by the block
    int aBegin = size * TILE_WIDTH * by;

    // Index of the last sub-matrix of A processed by the block
    int aEnd = aBegin + size - 1;

    // Step size used to iterate through the sub-matrices of A
    int aStep = TILE_WIDTH;

    // Index of the first sub-matrix of B processed by the block
    int bBegin = TILE_WIDTH * bx;

    // Step size used to iterate through the sub-matrices of B
    int bStep = TILE_WIDTH * size;

    // The element of the block sub-matrix that is computed by the thread
    float Csub = 0;



    // Loop over all the sub-matrices of A and B required to compute the block sub-matrix

    for (int a = aBegin, b = bBegin; a <= aEnd; a += aStep, b += bStep)
    {
        // Shared memory for the sub-matrices of A and B
        __shared__ float As[TILE_WIDTH][TILE_WIDTH];
        __shared__ float Bs[TILE_WIDTH][TILE_WIDTH];


        // Load the matrices from global memory to shared memory, each thread loads one element of each matrix
        As[ty][tx] = A[a + size * ty + tx];
        Bs[ty][tx] = B[b + size * ty + tx];

        // Synchronize to make sure the matrices are loaded
        __syncthreads();

        #pragma unroll
        // Multiply the two matrices together, each thread computes one element of the block sub-matrix
        for (int k = 0; k < TILE_WIDTH; ++k) 
            Csub += As[ty][k] * Bs[k][tx];


        // Synchronize to make sure that the preceding computation is done before loading two new sub-matrices of A and B in the next iteration
        __syncthreads();
    }

    // Write the block sub-matrix to global memory, each thread writes one element
    int c = size * TILE_WIDTH * by + TILE_WIDTH * bx;
    C[c + size * ty + tx] = Csub;












}*/


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


/**** GRID-STRIDE MATMUL ****/
__global__ void matMulGridStride(float* A, float* B, float* C, int m, int k, int n) {
    int ROW = blockIdx.x*blockDim.x+threadIdx.x;
    int COL = blockIdx.y*blockDim.y+threadIdx.y;

    int Rstride = blockDim.x*gridDim.x;
    int Cstride = blockDim.y*gridDim.y;    

    for (int r=ROW; r<m; r+=Rstride) {
        for (int c=COL; c<n; c+=Cstride) {        
            float tmpSum = 0.0f;
            for (int i = 0; i <k; ++i) {
                tmpSum += A[(r*k)+i] * B[(i*n)+c];
            }
            C[(r*n)+c] = tmpSum;
        }           
    }   
    return ;
}

/**** GRID-STRIDE SQUARE MATMUL ****/
__global__ void squareMatMulGridStrideKer(float* A, float* B, float* C, int N) {

    int ROW = blockIdx.x*blockDim.x+threadIdx.x;
    int COL = blockIdx.y*blockDim.y+threadIdx.y;

    int Rstride = blockDim.x*gridDim.x;
    int Cstride = blockDim.y*gridDim.y;    

    float tmpSum = 0.0f;
    for (int k=ROW; k<N; k+=Rstride) {
        for (int j=COL; j<N; j+=Cstride) {        
            tmpSum=0;
            for (int i = 0; i < N; i++) {
                tmpSum += A[(k*N)+i] * B[(i*N)+j];
            }
            C[(k*N)+j] = tmpSum;
        }               
    }  
    return ;
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


/*******************
**KERNEL LAUNCHERS**
********************/

/**** SQUARE MATMUL ****/
void streamSquareMatMul(float *A, float *B, float *C, float *Ad, float *Bd, float *Cd, 
            int n, cudaStream_t strm, bool shared)
{
    int size = n*n;
    int bytesMat = size*sizeof(float);
    // H2D memCopy
    gpuErrchk( cudaMemcpyAsync(Ad, A, bytesMat, cudaMemcpyHostToDevice, strm) );    
    gpuErrchk( cudaMemcpyAsync(Bd, B, bytesMat, cudaMemcpyHostToDevice, strm) );   
    // Grid and Block setting
    launchConfig(n, n);
    dim3 dimBlock( BLOCK,BLOCK,1 );
    /*#ifdef LOWPAR        
        GRIDx = 1;
    #else
        int sizeX;
        if (n%BLOCK == 0) sizeX = n;
        else sizeX = n+BLOCK-1;
        GRIDx = sizeX/BLOCK;
    #endif*/
    dim3 dimGrid( GRIDx,GRIDx,1 ); 
    // Kernel launch
    if(shared)
        sharedMatMulKernel<<<dimGrid, dimBlock, 0, strm>>>(Ad, Bd, Cd, n);
    else
        squareMatMulKernel<<<dimGrid, dimBlock, 0, strm>>>(Ad, Bd, Cd, n);
    // D2H memCopy
    gpuErrchk( cudaMemcpyAsync( C, Cd, bytesMat, cudaMemcpyDeviceToHost, strm) );

    #ifndef MEASURES
        gpuErrchk( cudaPeekAtLastError() );
    #endif 
}

void squareMatMul(float *A, float *B, float *C, float *Ad, float *Bd, float *Cd, int n, bool shared)
{
    int size = n*n;
    int bytesMat = size*sizeof(float);

    gpuErrchk( cudaMemcpy(Ad, A, bytesMat, cudaMemcpyHostToDevice) );    
    gpuErrchk( cudaMemcpy(Bd, B, bytesMat, cudaMemcpyHostToDevice) );   

    launchConfig(n, n);
    dim3 dimBlock( BLOCK,BLOCK,1 );
    /*#ifdef LOWPAR        
        GRIDx = 1;
    #else
        int sizeX;
        if (n%BLOCK == 0) sizeX = n;
        else sizeX = n+BLOCK-1;

        GRIDx = (sizeX)/BLOCK;
    #endif*/
    dim3 dimGrid( GRIDx,GRIDx,1 ); 
    if(shared)
        sharedMatMulKernel<<<dimGrid, dimBlock>>>(Ad, Bd, Cd, n);
    else
        squareMatMulKernel<<<dimGrid, dimBlock>>>(Ad, Bd, Cd, n);
    //squareMatMulGridStrideKer<<<dimGrid, dimBlock>>>(Ad, Bd, Cd, n);

    gpuErrchk( cudaMemcpy( C, Cd, bytesMat, cudaMemcpyDeviceToHost) );

    #ifndef MEASURES
        gpuErrchk( cudaPeekAtLastError() );
    #endif 
}





/**** NON SQUARE MATMUL ****/
#ifdef MATMUL
void streamMatMul(float *A, float *B, float *C, float *Ad, float *Bd, float *Cd, 
        int m, int k, int n, cudaStream_t strm)
{
    int bytesA = m*k*sizeof(float);
    int bytesB = k*n*sizeof(float);
    int bytesC = m*n*sizeof(float);
    // H2D memCopy
    cudaMemcpyAsync(Ad, A, bytesA, cudaMemcpyHostToDevice, strm);    
    cudaMemcpyAsync(Bd, B, bytesB, cudaMemcpyHostToDevice, strm);   
    // Grid and Block setting    
    launchConfig(m, n);
    dim3 dimBlock( BLOCK,BLOCK,1 );
    /*#ifdef LOWPAR
        GRIDx = 1;
        GRIDy = 1;
    #else
        int sizeX,sizeY;
        if (m%BLOCK == 0) sizeX = m;
        else sizeX = m+BLOCK-1;

        if (n%BLOCK == 0) sizeY = n;
        else sizeY = n+BLOCK-1;

        GRIDx = (sizeX)/BLOCK;
        GRIDy = (sizeY)/BLOCK;
    #endif*/
    dim3 dimGrid( GRIDx,GRIDy,1 ); 
    // Kernel launch
    matMulKernel<<<dimGrid, dimBlock, 0, strm>>>(Ad, Bd, Cd, m,  k,  n);
    // D2H memCopy
    cudaMemcpyAsync( C, Cd, bytesC, cudaMemcpyDeviceToHost, strm);
}


void matMul(float *A, float *B, float *C, float *Ad, float *Bd, float *Cd, 
        int m, int k, int n)
{
    int bytesA = m*k*sizeof(float);
    int bytesB = k*n*sizeof(float);
    int bytesC = m*n*sizeof(float);
    // H2D memCopy
    cudaMemcpy(Ad, A, bytesA, cudaMemcpyHostToDevice);    
    cudaMemcpy(Bd, B, bytesB, cudaMemcpyHostToDevice);   
    // Grid and Block setting
    launchConfig(m, n);
    dim3 dimBlock( BLOCK,BLOCK,1 );
    /*#ifdef LOWPAR
        GRIDx = 1;
        GRIDy = 1;
    #else
        int sizeX,sizeY;
        if (m%BLOCK == 0) sizeX = m;
        else sizeX = m+BLOCK-1;

        if (n%BLOCK == 0) sizeY = n;
        else sizeY = n+BLOCK-1;

        GRIDx = (sizeX)/BLOCK;
        GRIDy = (sizeY)/BLOCK;
    #endif*/
    dim3 dimGrid( GRIDx,GRIDy,1 ); 
    // Kernel launch
    matMulKernel<<<dimGrid, dimBlock>>>(Ad, Bd, Cd, m,  k,  n);
    // D2H memCopy
    cudaMemcpy( C, Cd, bytesC, cudaMemcpyDeviceToHost);
}



/* SHARED MEMORY MATMUL 
void squareSharedMatMul(float *A, float *B, float *C, float *Ad, float *Bd, float *Cd, int n)
{
    int size = n*n;
    int bytesMat = size*sizeof(float);

    gpuErrchk( cudaMemcpy(Ad, A, bytesMat, cudaMemcpyHostToDevice) );    
    gpuErrchk( cudaMemcpy(Bd, B, bytesMat, cudaMemcpyHostToDevice) );   

    launchConfig(n, n);
    dim3 dimBlock( BLOCK,BLOCK,1 );
    /*#ifdef LOWPAR        
        GRIDx = 1;
    #else
        int sizeX;
        if (n%BLOCK == 0) sizeX = n;
        else sizeX = n+BLOCK-1;

        GRIDx = (sizeX)/BLOCK;
    #endif
    dim3 dimGrid( GRIDx,GRIDx,1 ); 
    sharedMatMulKernel<<<dimGrid, dimBlock>>>(Ad, Bd, Cd, n);

    gpuErrchk( cudaMemcpy( C, Cd, bytesMat, cudaMemcpyDeviceToHost) );
}*/


/* void streamSquareSharedMatMul(float *A, float B*, float C*, float *Ad, float *Bd, float *Cd, int n, cudaStream_t strm){
    int size = n*n;
    int bytesMat = size*sizeof(float);
    // H2D memCopy
    gpuErrchk( cudaMemcpyAsync(Ad, A, bytesMat, cudaMemcpyHostToDevice, strm) );    
    gpuErrchk( cudaMemcpyAsync(Bd, B, bytesMat, cudaMemcpyHostToDevice, strm) );   
    // Grid and Block setting
    launchConfig(n, n);
    dim3 dimBlock( BLOCK,BLOCK,1 );
    /*#ifdef LOWPAR        
        GRIDx = 1;
    #else
        int sizeX;
        if (n%BLOCK == 0) sizeX = n;
        else sizeX = n+BLOCK-1;
        GRIDx = sizeX/BLOCK;
    #endif
    dim3 dimGrid( GRIDx,GRIDx,1 ); 
    // Kernel launch
    sharedMatMulKernel<<<dimGrid, dimBlock, 0, strm>>>(Ad, Bd, Cd, n);
    // D2H memCopy
    gpuErrchk( cudaMemcpyAsync( C, Cd, bytesMat, cudaMemcpyDeviceToHost, strm) );
    #ifndef MEASURES
        gpuErrchk( cudaPeekAtLastError() );
    #endif 
}*/

#endif


/**** BLURBOX ****/
#ifdef BLURBOX
void streamBlurBoxFilter (unsigned char *in_h, unsigned char *out_h, unsigned char *in_d, unsigned char *out_d, 
                    int width, int height, cudaStream_t strm)
{          
    int size = width*height*3;
    // H2D memCopy
    gpuErrchk( cudaMemcpyAsync(in_d, in_h, size, cudaMemcpyHostToDevice, strm) );  
    // Grid and Block setting
    #ifdef LOWPAR   
        GRIDx = 1;     
        //blurBoxGridStride<<<gridDims, blockDims, 0, strm>>>(in_d, out_d, width, height); 
    #else
        GRIDx = (unsigned int)((size+BLOCK-1)/BLOCK);
    #endif
    dim3 blockDims( BLOCK,1,1 );
    dim3 gridDims( GRIDx,1,1 );
    // Kernel launch
    #ifdef LOWPAR   
        blurBoxGridStride<<<gridDims, blockDims, 0, strm>>>(in_d, out_d, width, height); 
    #else
        blurBoxFilterKer<<<gridDims, blockDims, 0, strm>>>(in_d, out_d, width, height); 
    #endif
    //blurBoxFilterKer<<<gridDims, blockDims, 0, strm>>>(in_d, out_d, width, height); 
    // D2H memCopy
    gpuErrchk( cudaMemcpyAsync( out_h, out_d, size, cudaMemcpyDeviceToHost, strm) );
    //cudaDeviceSynchronize();
    #ifndef MEASURES
        gpuErrchk( cudaPeekAtLastError() );
    #endif 

}

void blurBoxFilter (unsigned char *in_h, unsigned char *out_h, unsigned char *in_d, unsigned char *out_d, 
                    int width, int height)
{     
    int size = width*height*3;    
    // H2D memCopy
    gpuErrchk( cudaMemcpy(in_d,in_h, size, cudaMemcpyHostToDevice) );   
    // Grid and Block setting    
     
    #ifdef LOWPAR   
        GRIDx = 1;           
        //blurBoxGridStride<<<gridDims, blockDims>>>(in_d, out_d, width, height); 
    #else
        GRIDx = (unsigned int)((size+BLOCK-1)/BLOCK);
        //dim3 gridDims( GRIDx,1,1 );
    #endif
    dim3 blockDims( BLOCK,1,1 );   
    dim3 gridDims( GRIDx,1,1 ); 
    // Kernel launch
    #ifdef LOWPAR   
        blurBoxGridStride<<<gridDims, blockDims>>>(in_d, out_d, width, height); 
    #else
        blurBoxFilterKer<<<gridDims, blockDims>>>(in_d, out_d, width, height); 
    #endif
    //blurBoxFilterKer<<<gridDims, blockDims>>>(in_d, out_d, width, height); 
    // D2H memCopy
    gpuErrchk( cudaMemcpy( out_h, out_d, size, cudaMemcpyDeviceToHost) );
}
#endif

/**** BLURGAUSS ****/
/*#ifdef BLURGAUSS
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
#endif*/