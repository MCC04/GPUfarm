#!/bin/bash

rm -f ./results/dev_cos_st_fut.txt
touch ./results/dev_cos_st_fut.txt

rm -f ./profiling/dev_str*.txt
rm -f ./profiling/dev_futurelow*.txt

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
Ns=(24576 49152 98304 196608 393216 786432)

##### STREAM PAR #####
#parameters: deviceID, BLOCK, N_elements, M_iterations, nCUDAStreams, chunkSize
make cleancos
echo -e "${BLUE}compiling stream...${NC}"
echo ""
make stream

echo ***STREAM_NOSTREAM_test***
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
			./bin/cos/stream.out $GPU $B $N $m 0 0 >> ./results/dev_cos_st_fut.txt
		done
		echo -ne "$nTests \n"			
		nvprof --log-file ./profiling/dev_str$N-$m-$B-0.txt ./bin/cos/stream.out $GPU $B $N $m 0 0 >> ./results/dev_cos_st_fut.txt
				
			
		#done
	done
done

#########

echo ***STREAM_3_test***
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
			./bin/cos/stream.out $GPU $B $N $m 1 3 >> ./results/dev_cos_st_fut.txt
		done
		echo -ne "$nTests \n"			
		nvprof --log-file ./profiling/dev_str$N-$m-$B-3.txt ./bin/cos/stream.out $GPU $B $N $m 1 3 >> ./results/dev_cos_st_fut.txt
				
			
		#done
	done
done

#########

echo ***STREAM_NCORES_test***
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
			./bin/cos/stream.out $GPU $B $N $m 1 0 >> ./results/dev_cos_st_fut.txt
		done
		echo -ne "$nTests \n"			
		nvprof --log-file ./profiling/dev_str$N-$m-$B-cores.txt ./bin/cos/stream.out $GPU $B $N $m 1 0 >> ./results/dev_cos_st_fut.txt
				
			
		#done
	done
done


##### FUTURE #####
#parameters: deviceID, BLOCK, N_elements, M_iterations, cuStr[bool], strNum
make cleandplow
echo -e "${BLUE}compiling futurelow...${NC}"
echo ""
make futurelow

echo ***FUTURE_LOW_test***
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
			./bin/futurelow.out $GPU $B $N $m 1 0 >> ./results/dev_cos_st_fut.txt
		done
		echo -ne "$nTests \n"			
		nvprof --log-file ./profiling/dev_futurelow$N-$m-$B-cores.txt ./bin/futurelow.out $GPU $B $N $m 1 0 >> ./results/dev_cos_st_fut.txt

	done
done