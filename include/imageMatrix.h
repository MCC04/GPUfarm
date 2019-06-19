#include <iostream>
#include <cudaUtils.h>

extern int K_exec;
extern int M_iter;
extern int N_size;

extern int GRIDx;
extern int GRIDy;

template <typename T>  T getMatrixVal(T *mat, int row, int col, int width);
template <typename T>  void setMatrixVal(T *mat, int row, int col, int width, T val);
void randomMatrix (const int m, int n,float *mat);
void easyRandomMatrix (const int m, int n,float *mat, float var);

/*****Kernel launcers*****/
//MATRIX MULTIPLICATION
void newMatMulKer (float *A, float *B, float *C, float *Ad, float *Bd, float *Cd,
     int m, int k, int n, int chunk, cudaStream_t strm); 

void newSquareMatMulKer (float *A, float *B, float *C, float *Ad, float *Bd, float *Cd,
    int n, int chunk, cudaStream_t strm);

//IMAGE PROCESSING
void blurBoxFilter (unsigned char *img_in, unsigned char *img_out, unsigned char *in_d, unsigned char *out_d,
                    int width, int height, int bytesSize, cudaStream_t strm);

void blurGaussianfilter (unsigned char *img_in, unsigned char *img_out, unsigned char *in_d, unsigned char *out_d,
                         int width, int height, int bytesSize, int kerdim, float sigma, cudaStream_t strm);


