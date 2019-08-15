#!/bin/bash


rm -f ./results/dev_sp_low.txt
touch ./results/dev_sp_low.txt

rm -f ./profiling/dev_str_low*.txt

BLUE='\033[1;34m'
NC='\033[0m'
let GPU=3
#let GPU=0

let BLOCK=64
let SM=56


#################
###### COS ######
#################
Miters=(10000 500000 1000000)
BLOCK=(64 256 512 1024)
nStreams=(3 56 64 112)



##### DATA PAR #####
#parameters: deviceID, BLOCK, N_elements, M_iterations, nCUDAStreams, chunkSize
make cleandp
echo -e "${BLUE}compiling datapar...${NC}"
echo ""
make datapar

echo ***DATA_PAR_test***


for((k=1; k<=4; k*=2));
do
	for B in "${BLOCK[@]}"
		do
		let "N = $k*$SM*$B"
		
		#echo running with BLOCK = $B,  N = $N elements		
		
		for m in "${Miters[@]}"
		do
			#echo iterations M = $m 
			echo BLOCK = $B , sizeN = $N elements, kerM = $m 
			echo -n execIndex = 
			
			for((j=0; j<7; j+=1));
			do
				echo -n "$j , "
				./bin/datapar.out $GPU $B $N $m 0 0 >> ./results/dev_sp_low.txt
			done
			echo -ne "7 \n"			
			nvprof --log-file ./profiling/dev_datapar$N-$m-$B-$nstr.txt ./bin/datapar.out $GPU $B $N $m 0 0 >> ./results/dev_sp_low.txt
	
		done
	done
done


