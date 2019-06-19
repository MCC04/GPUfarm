#include <vector>
#include <future>
#include <iterator>
#include <cudaUtils.h>

struct hostData_t{
    float *x;
    int *clocks;
};

extern int K_exec;
extern int M_iter;
extern int N_size;

/**** UTILS ****/
void randomArray(float *x, int n);
inline void printCos(float *cosx, int size);
inline void printClocks(int *clocks, int size);

/**** KERNEL LAUNCHERS ****/
float emptyKer();
std::vector<std::future<hostData_t>> cosKerFuture(int M, int chunk, hostData_t out, float *x, float *x_d, int *clocks_d, cudaStream_t *strm, int nStreams, int offset);
void cosKerStream(int M, int chunk, float *x, float *cosx, float *x_d, int *clocks, int *clocks_d, cudaStream_t strm, int strBytes, int offset);





void cosKerStream(int m, int n,
    float *x, float *cosx,  int *clocks, int offset, cudaStream_t strm);



