
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

struct my_struct {
    float *x_vect;
    int *clocks;
    float eventTime;
};

extern int K_exec;
extern int M_iter;
extern int N_size;

void randomArray(float *x, int n);

/*****Kernel launcers*****/
float emptyKer();



void cosKer(my_struct *_xs, float *x_d, int *clocks_d, int chunkBytes,
            cudaEvent_t start, cudaEvent_t stop, cudaStream_t strm);




float cosKer(std::vector<my_struct> &getDatas, int chunk, int bytesSize );

void cosKerStream( int m, int n,
    float *x, int *clocks, 
    cudaStream_t strm, int offset);

float cosKerStream(
    cudaEvent_t start, cudaEvent_t stop,
    int m, int n,
    float *x, float *cosx,  int *clocks, 
    int offset, cudaStream_t strm);

