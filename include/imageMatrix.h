#include <iostream>
#include <cudaUtils.h>

extern int K_exec;
extern int M_iter;
extern int N_size;

extern int GRIDx;
extern int GRIDy;

template <typename T>  T getMatrixVal (T *mat, int row, int col, int width);
template <typename T>  void setMatrixVal (T *mat, int row, int col, int width, T val);
void randomMatrix (const int m, int n,float *mat);
void easyRandomMatrix (const int m, int n,float *mat, float var);
//void getGaussian (float* ker,int dim, float sigma);

/*****Kernel launcers*****/
//MATRIX MULTIPLICATION
void streamMatMul(float *A, float *B, float *C, float *Ad, float *Bd, float *Cd, 
        int m, int k, int n, cudaStream_t strm);

void matMul(float *A, float *B, float *C, float *Ad, float *Bd, float *Cd, 
        int m, int k, int n);

void streamSquareMatMul(float *A, float *B, float *C, float *Ad, float *Bd, float *Cd, 
            int n, cudaStream_t strm, bool shared); 

void squareMatMul(float *A, float *B, float *C, float *Ad, float *Bd, float *Cd, int n, bool shared);

//void streamSquareSharedMatMul(float *A, float B*, float *C, float *Ad, float *Bd, float *Cd,
  //          int n, cudaStream_t strm); 

//void squareSharedMatMul(float *A, float *B, float *C, float *Ad, float *Bd, float *Cd, int n);

//IMAGE PROCESSING
void streamBlurBoxFilter (unsigned char *img_in, unsigned char *img_out, unsigned char *in_d, unsigned char *out_d, 
                    int width, int height, cudaStream_t strm);

void blurBoxFilter (unsigned char *img_in, unsigned char *img_out, unsigned char *in_d, unsigned char *out_d, 
                    int width, int height);

//void blurGaussianfilter (unsigned char *img_in, unsigned char *img_out, unsigned char *in_d, unsigned char *out_d, 
  //                      float *ker_d, int width, int height, int bytesSize, int kerdim, cudaStream_t strm);
                         