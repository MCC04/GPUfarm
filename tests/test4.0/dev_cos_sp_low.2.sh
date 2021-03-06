#!/bin/bash

rm -f ./results/dev_sp_low.txt
touch ./results/dev_sp_low.txt

rm -f ./profiling/dev_str_low*.txt
rm -f ./profiling/dev_datapar*.txt

BLUE='\033[1;34m'
NC='\033[0m'
let GPU=3
#let GPU=0

let B=256
let SM=56

#################
###### COS ######
#################
Miters=(10000 500000 1000000)
nStreams=(0 3 56 64 112)
Ns=(114688 229376 458752 917504)

##### DATA PAR #####
#parameters: deviceID, BLOCK, N_elements, M_iterations, nCUDAStreams, chunkSize
make cleandp
echo -e "${BLUE}compiling datapar...${NC}"
echo ""
make datapar

echo ***DATA_PAR_test***
echo BLOCK = $B 

for N in "${Ns[@]}"
do	
	for m in "${Miters[@]}"
	do
		echo sizeN = $N elements, kerM = $m 
		echo -n execIndex = 
		
		for((j=0; j<7; j+=1));
		do
			echo -n "$j , "
			./bin/datapar.out $GPU $B $N $m 0 0 >> ./results/dev_sp_low.txt
		done
		echo -ne "7 \n"			
		sudo /usr/local/cuda-10.1/bin/nvprof --log-file ./profiling/dev_datapar$N-$m-$B-$nstr.txt ./bin/datapar.out $GPU $B $N $m 0 0 >> ./results/dev_sp_low.txt

	done
done


##### STREAM LOW HYB PAR #####
#parameters: deviceID, BLOCK, N_elements, M_iterations, nCUDAStreams, chunkSize
make cleandp
echo -e "${BLUE}compiling stream...${NC}"
echo ""
make streamlow

echo ***STREAM_LOW_HYBRID_test***
echo BLOCK = $B 

for N in "${Ns[@]}"
do			
	for m in "${Miters[@]}"
	do
		for nstr in "${nStreams[@]}"
		do
			echo sizeN = $N elements, kerM = $m , CUstreams = $nstr 
			echo -n execIndex = 
			
			for((j=0; j<7; j+=1));
			do
				echo -n "$j , "
				./bin/streamlow.out $GPU $B $N $m $nstr 1 >> ./results/dev_sp_low.txt
			done
			echo -ne "7 \n"			
			sudo /usr/local/cuda-10.1/bin/nvprof --log-file ./profiling/dev_str_low$N-$m-$B-$nstr.txt ./bin/streamlow.out $GPU $B $N $m $nstr 1 >> ./results/dev_sp_low.txt
				
			
		done
	done
done
