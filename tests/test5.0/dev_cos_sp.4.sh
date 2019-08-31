#!/bin/bash

rm -f ./results/dev_sp.txt
touch ./results/dev_sp.txt

rm -f ./profiling/dev_str*.txt
rm -f ./profiling/dev_hyb*.txt

BLUE='\033[1;34m'
NC='\033[0m'

let GPU=2
let SM=56
let B=1024

#################
###### COS ######
#################
Miters=(10000 500000 1000000)
nStreams=(0 3 56 64 112)
Ns=(114688 7340032 14680064 29360128)

##### STREAM PAR #####
#parameters: deviceID, BLOCK, N_elements, M_iterations, nCUDAStreams, chunkSize
make cleancos
echo -e "${BLUE}compiling stream...${NC}"
echo ""
make stream

echo ***STREAM_PAR_test***
echo BLOCK = $B 
for N in "${Ns[@]}"
do
	for m in "${Miters[@]}"
	do
		for nstr in "${nStreams[@]}"
		do
			echo sizeN = $N elements, kerM = $m , CUstreams = $nstr 
			echo -n execIndex = 
			
			for((j=0; j<4; j+=1));
			do
				echo -n "$j , "
				./bin/cos/stream.out $GPU $B $N $m $nstr 0 >> ./results/dev_sp.txt
			done
			echo -ne "4 \n"			
			sudo /usr/local/cuda-10.1/bin/nvprof --log-file ./profiling/dev_str$N-$m-$B-$nstr.txt ./bin/cos/stream.out $GPU $B $N $m $nstr 0 >> ./results/dev_sp.txt
				
			
		done
	done
done
#echo shittyface | sudo -S 


##### HYBRID PAR #####
#parameters: deviceID, BLOCK, N_elements, M_iterations, nCUDAStreams, chunkSize
echo ***HYBRID_PAR_test***
echo BLOCK = $B
for N in "${Ns[@]}"
do
	for m in "${Miters[@]}"
	do
		echo sizeN = $N elements, kerM = $m , CUstreams = $nstr 
		echo -n execIndex = 
		
		for((j=0; j<4; j+=1));
		do
			echo -n "$j , "
			./bin/cos/stream.out $GPU $B $N $m 3 1 >> ./results/dev_sp.txt
		done
		echo -ne "4 \n"			
		sudo /usr/local/cuda-10.1/bin/nvprof --log-file ./profiling/dev_hybr$N-$m-$B-$nstr.txt ./bin/cos/stream.out $GPU $B $N $m 3 1 >> ./results/dev_sp.txt
	done
done
