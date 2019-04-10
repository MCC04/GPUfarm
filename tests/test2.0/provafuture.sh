rm -f ./results/future.txt
touch ./results/future.txt

rm -f ./profiling/future*.txt
#touch ./profiling/future_m1.txt

#ARGS="device nExec kerIters elemNum" >> future_m1.txt
#standard

#for((k=1; k<=32; k*=2));
#do
#	echo running with k = $k
#	let "N = $k*56*32"
#	
#        for((i=10; i<=1250; i*=5));
#        do
#		for((k=1; k<=32; k*=2));
#		do
#			echo iterations M = $i
#		        ./a.out 1 $k $i $N >> ./results/future.txt
#	       	done
#        done
#        ./a.out 1 $k 2500 $N >> ./results/future.txt
#done


for((k=4; k<=16; k*=2));
do
	echo running with k = $k
	let "N = $k*56*32"
	
        for((i=50; i<=1250; i*=5));
        do
		for((j=4; j<=16; j*=2));
		do
			#echo profiling with k = 4
			#let "N = 4*56*32"        
        
        		#echo iterations M = $i
                	nvprof --log-file ./profiling/1_future-prova$k-$i.txt ./a.out 1 $k $i $N >> ./results/1_future-prova.txt

        #nvprof --log-file ./profiling/future$k-2500.txt ./a.out 1 $k 2500 $N 
		done
	done
done



for((j=4; j<=16; j*=2));
do
	for((k=4; k<=16; k*=2));
	do
		echo running with k = $k
		let "N = $k*56*32"
	
		for((i=50; i<=1250; i*=5));
		do
		
			#echo profiling with k = 4
			#let "N = 4*56*32"        
        
        		#echo iterations M = $i
                	nvprof --log-file ./profiling/2_future-prova$k-$i.txt ./a.out 1 $k $i $N >> ./results/2_future-prova.txt

        #nvprof --log-file ./profiling/future$k-2500.txt ./a.out 1 $k 2500 $N 
		done
	done
done

