#!/bin/bash

rm -f ./results/dev_sp_block.txt
touch ./results/dev_sp_block.txt

rm -f ./profiling/dev_str_block*.txt
rm -f ./profiling/dev_hyb_block*.txt

BLUE='\033[1;34m'
NC='\033[0m'

#let GPU=2
let GPU=0
let SM=56


#################
###### COS ######
#################
Miters=(10000 500000 1000000)
nStreams=(0 3 56 64 112)
BLOCK=(64 256 512 1024)

let N=229376

##### STREAM PAR #####
#parameters: deviceID, BLOCK, N_elements, M_iterations, nCUDAStreams, chunkSize
make cleancos
echo -e "${BLUE}compiling stream...${NC}"
echo ""
make stream

echo ***STREAM_PAR_test***
echo sizeN = $N elements
for B in "${BLOCK[@]}"
do
	for m in "${Miters[@]}"
	do
		for nstr in "${nStreams[@]}"
		do
			echo BLOCK = $B, kerM = $m , CUstreams = $nstr 
			echo -n execIndex = 
			
			for((j=0; j<7; j+=1));
			do
				echo -n "$j , "
				./bin/cos/stream.out $GPU $B $N $m $nstr 0 >> ./results/dev_sp_block.txt
			done
			echo -ne "7 \n"			
			sudo /usr/local/cuda-10.1/bin/nvprof --log-file ./profiling/dev_str_block$N-$m-$B-$nstr.txt ./bin/cos/stream.out $GPU $B $N $m $nstr 0 >> ./results/dev_sp_block.txt	
		done
	done
done



##### HYBRID PAR #####
#parameters: deviceID, BLOCK, N_elements, M_iterations, nCUDAStreams, chunkSize
echo ***HYBRID_PAR_test***
echo sizeN = $N elements
for B in "${BLOCK[@]}"
do
	for m in "${Miters[@]}"
	do
		echo BLOCK = $B, kerM = $m , CUstreams = $nstr 
		echo -n execIndex = 
		
		for((j=0; j<7; j+=1));
		do
			echo -n "$j , "
			./bin/cos/stream.out $GPU $B $N $m 3 1 >> ./results/dev_sp_block.txt
		done
		echo -ne "7 \n"			
		sudo /usr/local/cuda-10.1/bin/nvprof --log-file ./profiling/dev_hybr_block$N-$m-$B-$nstr.txt ./bin/cos/stream.out $GPU $B $N $m 3 1 >> ./results/dev_sp_block.txt
	done
done








