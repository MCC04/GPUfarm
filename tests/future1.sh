#!/bin/bash

rm -f ./results/future.txt
touch ./results/future.txt

rm -f ./profiling/future*.txt
#touch ./profiling/future_m1.txt

#ARGS="device nExec kerIters elemNum" >> future_m1.txt
#standard

for((k=1; k<=32; k*=2));
do
	echo running with k = $k
	let "N = $k*56*32"
	
        for((i=10; i<=1250; i*=5));
        do
        	echo iterations M = $i
                ./a.out 1 $k $i $N >> ./results/future.txt
        done
        ./a.out 1 $k 2500 $N >> ./results/future.txt
done


for((k=1; k<=32; k*=2));
do
        echo profiling with k = $k
        let "N = $k*56*32"
        
        for((i=10; i<=1250; i*=5));
        do
        	echo iterations M = $i
                nvprof --log-file ./profiling/future$k-$i.txt ./a.out 1 $k $i $N
        done
        nvprof --log-file ./profiling/future$k-2500.txt ./a.out 1 $k 2500 $N 
done

