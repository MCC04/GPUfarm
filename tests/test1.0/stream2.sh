#!/bin/bash
  
rm -f ./results/stream_m2.txt
touch ./results/stream_m2.txt

rm -f ./profiling/stream*-m2.txt
#touch ./profiling/stream_m2.txt

#ARGS="device nExec kerIters elemNum" >> stream_m2.txt
#standard

for((k=4; k<=16; k*=2));
do
        echo running for k = $k
        let "N = $k*56*32"
        #for ((i=0; i<7; i+=1));
        #do
                ./a.out 1 $k 1000 $N >> ./results/stream_m2.txt
        #done
done

for((k=4; k<=16; k*=2));
do
        echo profiling for k = $k
        let "N = $k*56*32"
        #for ((i=0; i<7; i+=1));
        #do
                nvprof --log-file ./profiling/stream$k-m2.txt ./a.out 0 $k 1000 $N
        #done
done

