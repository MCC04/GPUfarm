#!/bin/bash

rm -f ./results/dev_blur_dp_str.txt
touch ./results/dev_blur_dp_str.txt

rm -f ./profiling/dev_blur_str*.txt
rm -f ./profiling/dev_blur_dp*.txt

BLUE='\033[1;34m'
NC='\033[0m'

let GPU=2
let B=1024
#let SM=56

let nTests=4

#################
###### IMG ######
#################
imgSize=(128 256 512)
#nStreams=(0 3 56)
nImgs=(64 256 1024) # 14680064 29360128)
dpSize=(1024 2048 4096 8192)

##### IMG DATA PAR #####
#parameters: deviceID, BLOCK, cuStr[bool], strNum, width, height, numImages
make cleanmat
echo -e "${BLUE}compiling blurbox...${NC}"
echo ""
make blurbox

echo ***DATAPAR_BLUR_test***
echo BLOCK = $B 

for N in "${dpSize[@]}"
do	
	#for m in "${nMats[@]}"
	#do
	echo size = $N, images num = 1 
	echo -n execIndex = 
	
	for((j=0; j<nTests; j+=1));
	do
		echo -n "$j , "
		./bin/mat/blurbox.out $GPU $B 0 0 $N $N 1 >> ./results/dev_blur_dp_str.txt
	done
	echo -ne "$nTests \n"			
	sudo /usr/local/cuda-10.1/bin/nvprof --log-file ./profiling/dev_blur_dp$N-$m-$B.txt ./bin/mat/blurbox.out $GPU $B 0 0 $N $N 1 >> ./results/dev_blur_dp_str.txt

	#done
done


##### STREAM PAR #####
#parameters: deviceID, BLOCK, cuStr[bool], strNum, square[bool], shared[bool], numMats, M [, K, N]
#make cleancos
#echo -e "${BLUE}compiling stream...${NC}"
#echo ""
#make stream

echo ***BLUR_NOSTREAM_test***
echo BLOCK = $B 

for N in "${imgSize[@]}"
do	
	for m in "${nImgs[@]}"
	do
		echo size = $N, images num = $m 
		echo -n execIndex = 
		
		for((j=0; j<nTests; j+=1));
		do
			echo -n "$j , "
			./bin/mat/blurbox.out $GPU $B 0 0 $N $N $m >> ./results/dev_blur_dp_str.txt
		done
		echo -ne "$nTests \n"			
		sudo /usr/local/cuda-10.1/bin/nvprof --log-file ./profiling/dev_blur_str$N-$m-$B-0.txt ./bin/mat/blurbox.out $GPU $B 0 0 $N $N $m >> ./results/dev_blur_dp_str.txt

	done
done

#########

echo ***BLUR_STREAM_3_test***
echo BLOCK = $B 

for N in "${imgSize[@]}"
do	
	for m in "${nImgs[@]}"
	do
		echo size = $N, images num = $m 
		echo -n execIndex = 
		
		for((j=0; j<nTests; j+=1));
		do
			echo -n "$j , "
			./bin/mat/blurbox.out $GPU $B 1 3 $N $N $m >> ./results/dev_blur_dp_str.txt
		done
		echo -ne "$nTests \n"			
		sudo /usr/local/cuda-10.1/bin/nvprof --log-file ./profiling/dev_blur_str$N-$m-$B-0.txt ./bin/mat/blurbox.out $GPU $B 1 3 $N $N $m >> ./results/dev_blur_dp_str.txt

	done
done

#########

echo ***BLUR_STREAM_NCORES_test***
echo BLOCK = $B 

for N in "${imgSize[@]}"
do	
	for m in "${nImgs[@]}"
	do
		echo size = $N, images num = $m 
		echo -n execIndex = 
		
		for((j=0; j<nTests; j+=1));
		do
			echo -n "$j , "
			./bin/mat/blurbox.out $GPU $B 1 0 $N $N $m >> ./results/dev_blur_dp_str.txt
		done
		echo -ne "$nTests \n"			
		sudo /usr/local/cuda-10.1/bin/nvprof --log-file ./profiling/dev_blur_str$N-$m-$B-0.txt ./bin/mat/blurbox.out $GPU $B 1 0 $N $N $m >> ./results/dev_blur_dp_str.txt

	done
done



