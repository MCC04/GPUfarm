#include <cuda_runtime.h>


__global__ void myKer(float* a) {
}


int main(){
    float* a;
    const size_t size_bytes = 10;
    cudaMalloc((void**)&a, size_bytes);
    myKer<<<1,1>>>(a);
    cudaFree(a);
}