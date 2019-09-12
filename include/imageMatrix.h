#include <iostream>
#include <cudaUtils.h>

extern unsigned int BLOCK;
extern unsigned int GRIDx;
extern unsigned int GRIDy;

template <typename T> inline T getMatrixVal (T *mat, int row, int col, int width);
template <typename T> inline void setMatrixVal (T *mat, int row, int col, int width, T val);
void randomMatrix (const int m, int n,float *mat);
void launchConfig(int m, int n);


/*****Kernel launcers*****/

//MATRIX MULTIPLICATION
void streamMatMul(float *A, float *B, float *C, float *Ad, float *Bd, float *Cd, 
        int m, int k, int n, cudaStream_t strm);

void matMul(float *A, float *B, float *C, float *Ad, float *Bd, float *Cd, 
        int m, int k, int n);

void streamSquareMatMul(float *A, float *B, float *C, float *Ad, float *Bd, float *Cd, 
            int n, cudaStream_t strm, bool shared); 

void squareMatMul(float *A, float *B, float *C, float *Ad, float *Bd, float *Cd, int n, bool shared);



//IMAGE PROCESSING
void streamBlurBoxFilter (unsigned char *img_in, unsigned char *img_out, unsigned char *in_d, unsigned char *out_d, 
                    int width, int height, cudaStream_t strm);

void blurBoxFilter (unsigned char *img_in, unsigned char *img_out, unsigned char *in_d, unsigned char *out_d, 
                    int width, int height);

        