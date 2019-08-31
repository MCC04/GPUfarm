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

let nTests=6

#################
###### COS ######
#################
Miters=(10000 500000 1000000)
#nStreams=(0 3 56)
Ns=(114688 1835008 7340032) # 14680064 29360128)

##### DATA PAR #####
#parameters: deviceID, BLOCK, N_elements, M_iterations, cuStr[bool], strNum
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
		
		for((j=0; j<nTests; j+=1));
		do
			echo -n "$j , "
			./bin/datapar.out $GPU $B $N $m 0 0 >> ./results/dev_cos_dp_stl.txt
		done
		echo -ne "$nTests \n"			
		sudo /usr/local/cuda-10.1/bin/nvprof --log-file ./profiling/dev_datapar$N-$m-$B.txt ./bin/datapar.out $GPU $B $N $m 0 0 >> ./results/dev_cos_dp_stl.txt

	done
done


##### STREAM LOW PAR #####
#parameters: deviceID, BLOCK, N_elements, M_iterations, cuStr[bool], strNum
make cleandp
echo -e "${BLUE}compiling stream...${NC}"
echo ""
make streamlow

echo ***STREAM_LOW_NOSTREAM_test***
echo BLOCK = $B 

for N in "${Ns[@]}"
do			
	for m in "${Miters[@]}"
	do
		#for nstr in "${nStreams[@]}"
		#do
		echo sizeN = $N elements, kerM = $m , CUstreams = 0 
		echo -n execIndex = 
		
		for((j=0; j<nTests; j+=1));
		do
			echo -n "$j , "
			./bin/streamlow.out $GPU $B $N $m 0 0 >> ./results/dev_cos_dp_stl.txt
		done
		echo -ne "$nTests \n"			
		sudo /usr/local/cuda-10.1/bin/nvprof --log-file ./profiling/dev_str_low$N-$m-$B-0.txt ./bin/streamlow.out $GPU $B $N $m 0 0 >> ./results/dev_cos_dp_stl.txt
				
			
		#done
	done
done

#########

echo ***STREAM_LOW_3_STREAM_test***
echo BLOCK = $B 

for N in "${Ns[@]}"
do			
	for m in "${Miters[@]}"
	do
		#for nstr in "${nStreams[@]}"
		#do
		echo sizeN = $N elements, kerM = $m , CUstreams = 3 
		echo -n execIndex = 
		
		for((j=0; j<nTests; j+=1));
		do
			echo -n "$j , "
			./bin/streamlow.out $GPU $B $N $m 1 3 >> ./results/dev_cos_dp_stl.txt
		done
		echo -ne "$nTests \n"			
		sudo /usr/local/cuda-10.1/bin/nvprof --log-file ./profiling/dev_str_low$N-$m-$B-3.txt ./bin/streamlow.out $GPU $B $N $m 1 3 >> ./results/dev_cos_dp_stl.txt
				
			
		#done
	done
done

#########

echo ***STREAM_LOW_NCORES_STREAM_test***
echo BLOCK = $B 

for N in "${Ns[@]}"
do			
	for m in "${Miters[@]}"
	do
		#for nstr in "${nStreams[@]}"
		#do
		echo sizeN = $N elements, kerM = $m , CUstreams = nCores 
		echo -n execIndex = 
		
		for((j=0; j<nTests; j+=1));
		do
			echo -n "$j , "
			./bin/streamlow.out $GPU $B $N $m 1 0 >> ./results/dev_cos_dp_stl.txt
		done
		echo -ne "$nTests \n"			
		sudo /usr/local/cuda-10.1/bin/nvprof --log-file ./profiling/dev_str_low$N-$m-$B-cores.txt ./bin/streamlow.out $GPU $B $N $m 1 0 >> ./results/dev_cos_dp_stl.txt
				
			
		#done
	done
done
