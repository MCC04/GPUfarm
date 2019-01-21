#!/bin/bash

rm -f ./results/oneSm.txt
touch ./results/oneSm.txt

rm -f ./profiling/oneSm*.txt
#touch ./profiling/oneSm.txt

#ARGS="device nExec kerIters elemNum" >> oneSm.txt
#standard

for((k=4; k<=16; k*=2));
do
	echo running for k = $k
	let "N = $k*56*32"
        #for ((i=0; i<7; i+=1));
        #do
                ./a.out 0 $k 500 $N >> ./results/oneSm.txt
        #done
done


for((k=4; k<=16; k*=2));
do
        echo profiling for k = $k
        let "N = $k*56*32"
        #for ((i=0; i<7; i+=1));
        #do
                nvprof --log-file ./profiling/oneSm$k.txt ./a.out 0 $k 500 $N
        #done
done
