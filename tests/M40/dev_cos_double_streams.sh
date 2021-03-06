#!/bin/bash

rm -f ./results/dev_cos_dp_stl.txt
touch ./results/dev_cos_dp_stl.txt

rm -f ./profiling/dev_str_low*.txt
rm -f ./profiling/dev_datapar*.txt

BLUE='\033[1;34m'
NC='\033[0m'

let GPU=0
let B=1024
#let SM=56

let nTests=4

#################
###### COS ######
#################
Miters=(10000 400000 800000)
#nStreams=(0 3 56)
Ns=(24576 49152 98304 196608 393216 786432) # 14680064 29360128)

##### DATA PAR #####
#parameters: deviceID, BLOCK, N_elements, M_iterations, cuStr[bool], strNum



##### STREAM LOW PAR #####
#parameters: deviceID, BLOCK, N_elements, M_iterations, cuStr[bool], strNum
make cleandplow
echo -e "${BLUE}compiling stream...${NC}"
echo ""
make streamlow



#########

echo ***STREAM_LOW_48_STREAM_test***
echo BLOCK = $B 

for N in "${Ns[@]}"
do			
	for m in "${Miters[@]}"
	do
		#for nstr in "${nStreams[@]}"
		#do
		echo sizeN = $N elements, kerM = $m , CUstreams = 48
		echo -n execIndex = 
		
		for((j=0; j<nTests; j+=1));
		do
			echo -n "$j , "
			./bin/streamlow.out $GPU $B $N $m 1 48 >> ./results/dev_cos_dp_stl.txt
		done
		echo -ne "$nTests \n"			
		nvprof --log-file ./profiling/dev_str_low$N-$m-$B-48.txt ./bin/streamlow.out $GPU $B $N $m 1 48 >> ./results/dev_cos_dp_stl.txt
				
			
		#done
	done
done

#########


