#!/bin/bash
  
rm -f ./results/managed_m2.txt
touch ./results/managed_m2.txt

rm -f ./profiling/managed_m2.txt
touch ./profiling/managed_m2.txt

#ARGS="device nExec kerIters elemNum" >> managed_m2.txt
#standard

for((k=4; k<=16; k*=2));
do
        echo running for k = $k
        let "N = $k*56*32"
        #for ((i=0; i<7; i+=1));
        #do
                ./a.out 3 $k 1000 $N >> ./results/managed_m2.txt
        #done
done


for((k=4; k<=16; k*=2));
do
        echo profiling for k = $k
        let "N = $k*56*32"
        #for ((i=0; i<7; i+=1));
        #do
               nvprof --log-file ./profiling/managed_m2.txt ./a.out 3 $k 1000 $N 
        #done
done

