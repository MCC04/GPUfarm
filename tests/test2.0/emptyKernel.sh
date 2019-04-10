rm -f ./results/emptyKer.txt
touch ./results/emptyKer.txt

rm -f ./profiling/emptyKer*.txt
#touch ./profiling/emptyKer_m2.txt

#ARGS="device nExec kerIters elemNum" >> emptyKer_m2.txt
#standard

for((k=1; k<=32; k*=2));
do
	echo running with k = $k
	let "N = $k*56*32"
	
        ./a.out 1 $k 0 $N >> ./results/emptyKer.txt
  	

done


for((k=1; k<=32; k*=2));
do
        echo profiling with k = $k
        let "N = $k*56*32"
        
	nvprof --log-file ./profiling/emptyKer$k.txt ./a.out 1 $k 0 $N 
      
done
