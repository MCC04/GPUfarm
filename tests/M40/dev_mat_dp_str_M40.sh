#!/bin/bash

rm -f ./results/dev_mat_dp_str.txt
touch ./results/dev_mat_dp_str.txt

rm -f ./profiling/dev_mat_str*.txt
rm -f ./profiling/dev_mat_dp*.txt

BLUE='\033[1;34m'
NC='\033[0m'

let GPU=2
let B=32
#let SM=56

let nTests=4

#################
###### MAT ######
#################
matSize=(64 128 256 512 1024)
nMats=(100 196 400 784) # 14680064 29360128)
dpSize=(1280 1792 2560 3584 5120 7168)

##### MAT DATA PAR #####
#parameters: deviceID, BLOCK, cuStr[bool], strNum, square[bool], shared[bool], numMats, M [, K, N]
make cleanmat
echo -e "${BLUE}compiling matmul...${NC}"
echo ""
make matmul

echo ***DATAPAR_MATMUL_test***
echo BLOCK = $B 

for N in "${dpSize[@]}"
do	
	#for m in "${nMats[@]}"
	#do
	echo size = $N, matrices num = 1 
	echo -n execIndex = 
	
	for((j=0; j<nTests; j+=1));
	do
		echo -n "$j , "
		./bin/mat/matmul.out $GPU $B 0 0 1 0 1 $N >> ./results/dev_mat_dp_str.txt
	done
	echo -ne "$nTests \n"			
	nvprof --log-file ./profiling/dev_mat_dp$N-$m-$B.txt ./bin/mat/matmul.out $GPU $B 0 0 1 0 1 $N >> ./results/dev_mat_dp_str.txt

	#done
done


##### STREAM PAR #####
#parameters: deviceID, BLOCK, cuStr[bool], strNum, square[bool], shared[bool], numMats, M [, K, N]
#make cleancos
#echo -e "${BLUE}compiling stream...${NC}"
#echo ""
#make stream

echo ***MATMUL_NOSTREAM_test***
echo BLOCK = $B 

for N in "${matSize[@]}"
do	
	for m in "${nMats[@]}"
	do
		echo size = $N, matrices num = $m 
		echo -n execIndex = 
		
		for((j=0; j<nTests; j+=1));
		do
			echo -n "$j , "
			./bin/mat/matmul.out $GPU $B 0 0 1 0 $m $N >> ./results/dev_mat_dp_str.txt
		done
		echo -ne "$nTests \n"			
		nvprof --log-file ./profiling/dev_mat_str$N-$m-$B-0.txt ./bin/mat/matmul.out $GPU $B 0 0 1 0 $m $N >> ./results/dev_mat_dp_str.txt

	done
done

#########

echo ***MATMUL_STREAM_3_test***
echo BLOCK = $B 

for N in "${matSize[@]}"
do	
	for m in "${nMats[@]}"
	do
		echo size = $N, matrices num = $m 
		echo -n execIndex = 
		
		for((j=0; j<nTests; j+=1));
		do
			echo -n "$j , "
			./bin/mat/matmul.out $GPU $B 1 3 1 0 $m $N >> ./results/dev_mat_dp_str.txt
		done
		echo -ne "$nTests \n"			
		nvprof --log-file ./profiling/dev_mat_str$N-$m-$B-3.txt ./bin/mat/matmul.out $GPU $B 1 3 1 0 $m $N >> ./results/dev_mat_dp_str.txt

	done
done

#########

echo ***MATMUL_STREAM_NCORES_test***
echo BLOCK = $B 

for N in "${matSize[@]}"
do	
	for m in "${nMats[@]}"
	do
		echo size = $N, matrices num = $m 
		echo -n execIndex = 
		
		for((j=0; j<nTests; j+=1));
		do
			echo -n "$j , "
			./bin/mat/matmul.out $GPU $B 1 0 1 0 $m $N >> ./results/dev_mat_dp_str.txt
		done
		echo -ne "$nTests \n"			
		nvprof --log-file ./profiling/dev_mat_str$N-$m-$B-cores.txt ./bin/mat/matmul.out $GPU $B 1 0 1 0 $m $N >> ./results/dev_mat_dp_str.txt

	done
done



