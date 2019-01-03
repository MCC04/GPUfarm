#include <cuda_runtime.h>
#include <iostream>
#include <stdlib.h>
#include <ctime>
#include <unistd.h>

//workers computing square of rands
__global__ void kerSquare(int *randsDev,int* resDev){
    int myId = blockIdx.x * blockDim.x + threadIdx.x;

    //std::cout << myId << ", ";

    resDev[myId] = randsDev[myId] * randsDev[myId];
}

int main(){
    std::srand(std::time(NULL));
    int n = 20000;
    int arraySize=2000;
    int size = arraySize*sizeof(int);
    int *randsDev, *resDev, tmp[arraySize], finalRes[n], offs;
    int count;
    int random_variable;
    unsigned int microseconds = 400;

    if(microseconds<=400){
        cudaMalloc(&resDev, size);
        dim3 grid(10,1);
        dim3 block(200,1);

        for(int i=0;i<n;i+=1){
            //emitter
            random_variable = std::rand()%100;
            tmp[count]=random_variable;

            count+=1;
            usleep(microseconds);
            if(count==arraySize){
                cudaMalloc(&randsDev, size);
                std::cout << "copying randoms to device mem"<< std::endl;
                cudaMemcpy(randsDev, tmp, size, cudaMemcpyHostToDevice);

                //worker
                std::cout << "calling ker function"<< std::endl;
                kerSquare<<<grid,block>>>(randsDev, resDev);

                //collector
                cudaMemcpy(tmp, resDev, size, cudaMemcpyDeviceToHost);
                std::cout << std::endl << "copying back results"<< std::endl;
                offs+=count;
                std::copy(tmp, tmp+arraySize-1, finalRes+offs);

                count=0;
            }
        }
    }
    else{
        //Execute on CPU?
    }

    for(int i=0;i<n;i+=1){
        std::cout<<"\t"<<finalRes[i];
    }

    std::cout<<std::endl;
    //free mem
    cudaFree(randsDev);
    cudaFree(resDev);
}