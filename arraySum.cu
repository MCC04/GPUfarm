#include<cuda_runtime.h>
#include<stdio.h>
#include<stdlib.h>

__global__ void kerArraySum(int *md,int* nd, int *pd){
    //int myId=threadIdx.x;

    int myId = blockIdx.x * blockDim.x + threadIdx.x;

    p[myId] = m[myId] + n[myId];
}

int main(){
    int size = 2000*sizeof(int);
    int m[2000],n[2000],p[2000],nd,md,pd;

    //arrays init
    for(int i=0;i<2000;i+=1){
        m[i]=i;
        n[i]=i;
    }

    //mem allocation and copy
    cudaMalloc((void**)&md, size);
    cudaMemcpy(md, m, size, cudaMemcpyHostToDevice);
    
    cudaMalloc((void**)&nd, size);
    cudaMemcpy(nd, nd, size, cudaMemcpyHostToDevice);
    
    cudaMalloc((void**)&pd, size);
    
    //setting grid and block dims
    dim3 grid(10,1);
    dim3 block(200,1);

    //calling the kernel funct
    kerArraySum<<<grid,block>>>(md,nd,pd,size);

    //copy results back to cpu mem
    cudaMemcpy(p, pd, size, cudaMemcpyDeviceToHost);

    for(int i=0;i<2000;i+=1){
        std::cout<<"\t"<<p[i];
    }
    std::cout<<std::endl;

    //free mem
    cudaFree(md);
    cudaFree(nd);
    cudaFree(pd);
}