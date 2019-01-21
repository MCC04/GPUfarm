rm -f ./results/oneSm.txt
touch ./results/oneSm.txt

rm -f ./profiling/oneSm*.txt
#touch ./profiling/oneSm_m2.txt

#ARGS="device nExec kerIters elemNum" >> oneSm_m2.txt
#standard

for((k=1; k<=32; k*=2));
do
	echo running with k = $k
	let "N = $k*56*32"
	
        for((i=10; i<=1250; i*=5));
        do
        	echo iterations M = $i
                ./a.out 1 $k $i $N >> ./results/oneSm.txt
  	done
        ./a.out 1 $k 2500 $N >> ./results/oneSm.txt
done


for((k=1; k<=32; k*=2));
do
        echo profiling with k = $k
        let "N = $k*56*32"
        
        for((i=10; i<=1250; i*=5));
        do
        	echo iterations M = $i
        	nvprof --log-file ./profiling/oneSm$k-$i.txt ./a.out 1 $k $i $N 
        done
        nvprof --log-file ./profiling/oneSm$k-2500.txt ./a.out 1 $k 2500 $N 
done
