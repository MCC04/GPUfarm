#!/bin/bash


rm -f ./results/dev_sp.txt
touch ./results/dev_sp.txt

rm -f ./profiling/dev_str*.txt
rm -f ./profiling/dev_hyb*.txt
rm -f ./profiling/dev_datapar*.txt

BLUE='\033[1;34m'
NC='\033[0m'
#let GPU=2
let GPU=0

let SM=56


#################
###### COS ######
#################

#BLOCK=(32 64 128 256 512 1024)
#nStreams=(0 3 23 32 64 56 112)

Miters=(10000 500000 1000000)
BLOCK=(64 256 512 1024)
nStreams=(0 3 56 64 112)


##### STREAM PAR #####
#parameters: deviceID, BLOCK, N_elements, M_iterations, nCUDAStreams, chunkSize
make cleancos
echo -e "${BLUE}compiling stream...${NC}"
echo ""
make stream

echo ***STREAM_PAR_test***


for B in "${BLOCK[@]}"
do
	for((k=1; k<=4; k*=2));
	do
		let "N = $k*$SM*$B"
		#echo running with BLOCK = $B,  N = $N elements		
		
		for m in "${Miters[@]}"
		do
			#echo iterations M = $m 			
			
			for nstr in "${nStreams[@]}"
			do
				echo BLOCK = $B , sizeN = $N elements, kerM = $m , CUstreams = $nstr 
				echo -n execIndex = 
				
				for((j=0; j<7; j+=1));
				do
					echo -n "$j , "
					./bin/cos/stream.out $GPU $B $N $m $nstr 0 >> ./results/dev_sp.txt
				done
				echo -ne "7 \n"			
				nvprof --log-file ./profiling/dev_str$N-$m-$B-$nstr.txt ./bin/cos/stream.out $GPU $B $N $m $nstr 0 >> ./results/dev_sp.txt
					
				
			done
		done
	done
done


##### HYBRID PAR #####
#parameters: deviceID, BLOCK, N_elements, M_iterations, nCUDAStreams, chunkSize


echo ***HYBRID_PAR_test***

for B in "${BLOCK[@]}"
do
	for((k=1; k<=4; k*=2));
	do
		let "N = $k*$SM*$B"		
		#echo running with BLOCK = $B,  N = $N elements		
		
		for m in "${Miters[@]}"
		do
			#echo iterations M = $m 	
			echo BLOCK = $B , sizeN = $N elements, kerM = $m , CUstreams = $nstr 
			echo -n execIndex = 
			
			for((j=0; j<7; j+=1));
			do
				echo -n "$j , "
				./bin/cos/stream.out $GPU $B $N $m 3 1 >> ./results/dev_sp.txt
			done
			echo -ne "7 \n"			
			nvprof --log-file ./profiling/dev_hybr$N-$m-$B-$nstr.txt ./bin/cos/stream.out $GPU $B $N $m 3 1 >> ./results/dev_sp.txt
		done
	done
done






