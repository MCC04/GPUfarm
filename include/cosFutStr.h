#include <vector>
#include <future>
#include <iterator>
#include <cudaUtils.h>

extern int M_iter;
extern int N_size;

/**** UTILS ****/
void randomArray(float *x, int n);
 void printCos(float *cosx, int size);

/**** KERNEL LAUNCHERS ****/
std::vector<std::future<float *>> streamFutureCosine(int M, int chunk, float *cosx, float *x, float *x_d, cudaStream_t *strm, int nStreams);
void streamCosine(int M, int chunk, float *x, float *cosx, float *x_d, cudaStream_t strm, int strBytes);
void unifiedStreamCosine(int m, int n, float *x, float *cosx, cudaStream_t strm);
void cosine(int m, int chunk, float *x, float *cosx, float *x_d);
float optimalCosKer( int m, int n, float *x, float *cosx, float *x_d);




