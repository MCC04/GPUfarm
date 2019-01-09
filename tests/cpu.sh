#!/bin/bash

rm -f ./results/cpu.txt
touch ./results/cpu.txt

rm -f ./profiling/cpu.txt
touch ./profiling/cpu.txt

#ARGS="device nExec kerIters elemNum" >> cpu.txt
#standard

for((k=4; k<=16; k*=2));
do
	echo running for k = $k
	let "N = $k*56*32"
        #for ((i=0; i<7; i+=1));
        #do
                ./a.out 0 $k 500 $N >> ./results/cpu.txt
        #done
done


#for((k=4; k<=16; k*=2));
#do
   #     echo profiling for k = $k
    #    let "N = $k*56*32"
        #for ((i=0; i<7; i+=1));
        #do
     #           nvprof --log-file ./profiling/future_m1.txt ./a.out 3 $k 500 $N
        #done
#done
