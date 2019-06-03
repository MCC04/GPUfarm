
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

#define MAXCOLS 70000

extern int K_exec;
extern int M_iter;
extern int N_size;

extern int GRIDx;
extern int GRIDy;

template <typename T> T getMatrixVal(T *mat, int row, int col, int width);
template <typename T> void setMatrixVal(T *mat, int row, int col, int width, T val);


/*****Kernel launcers*****/
float matMulKer(
    float *Ad, float *Bd, float *Cd, 
    int m, int k, int n, 
    cudaStream_t strm,
    cudaEvent_t start, cudaEvent_t stop);

float smallMatMulKer(
    float *Ad, float *Bd, float *Cd, float *C, 
    int m, int k, int n, 
    cudaStream_t strm, cudaEvent_t start, cudaEvent_t stop);

float blurGaussianfilter (
    unsigned char *img_in, unsigned char *img_out,
    int width, int height,int kerdim, float sigma,
    cudaStream_t strm, cudaEvent_t start, cudaEvent_t stop);

float blurBoxFilter (
    unsigned char *img_in, unsigned char *img_out,
    int width, int height, cudaStream_t strm,
    cudaEvent_t start, cudaEvent_t stop);






//NEW MAT MUL KERNELS

float newMatMulKer(
    float *Ad, float *Bd, float *Cd, float *C,
    int m, int k, int n, int chunk,
    cudaStream_t strm, cudaEvent_t start, cudaEvent_t stop);


    float newSquareMatMulKer(
    float *Ad, float *Bd, float *Cd, float *C,
    int n, int chunk,
    cudaStream_t strm, cudaEvent_t start, cudaEvent_t stop);