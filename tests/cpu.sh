#!/bin/bash

rm -f ./results/cpu.txt
touch ./results/cpu.txt


#ARGS="device nExec kerIters elemNum" >> cpu.txt
#standard


for((k=1; k<=32; k*=2));
do
	echo running with k = $k
	let "N = $k*56*32"
	
        for((i=10; i<=1250; i*=5));
        do
        	echo iterations M = $i
                ./a.out 1 $k $i $N >> ./results/cpu.txt
  	done
        ./a.out 1 $k 2500 $N >> ./results/cpu.txt
done



