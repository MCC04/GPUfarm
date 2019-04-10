#!/bin/bash

rm -f ./results/dev_imageMat_invert.txt
touch ./results/dev_imageMat_invert.txt

rm -f ./profiling/dev_imageMat_inv*.txt
#touch ./profiling/dev_imageMat_invert.txt

#ARGS="device nExec kerIters elemNum" >> dev_imageMat_invert.txt
#standard

BLUE='\033[1;34m'
NC='\033[0m'


let GPU=1

make clean
echo -e "${BLUE}compiling matmul...${NC}"
echo ""
make matmul
let "BLOCK=32"
echo ***MATMUL_test***

for((l=1; l<=5; l+=1));
do		
	let "M = $l*$BLOCK*8"
	let "K = $M+1"
	let "N = $M+2"
	echo running with M = $M , K = $K , N = $N 

	for((j=1; j<=5; j+=1));
	do
		let "Nmat = $j*56"
		echo number of matrices = $Nmat
		for((i=0; i<=15; i+=1));
		do
			echo iter = $i

			nvprof --log-file ./profiling/dev_imageMat_inv$l-$j.txt ./bin/matmul.out $GPU $BLOCK 4 $M $K $N $Nmat >> ./results/dev_imageMat_invert.txt
		done
	done
done


#for((k=1; k<=32; k*=2));
#do
#	echo running with k = $k
#	let "N = $k*56*32"

#	for((i=10; i<=1250; i*=5));
#	do
#		for((j=0; j<=15; j+=1));
#		do
#			echo iterations M = $i
#		        nvprof --log-file ./profiling/dev_imageMat_invert$k-$i.txt \
#		        	./blurbox.out $GPU $k $i $N >> ./results/dev_imageMat_invert.txt
#		done	
#	done
	
#	for((j=0; j<=15; j+=1));
#	do
#		nvprof --log-file ./profiling/dev_imageMat_invert$k-2500.txt \
#			./blurbox.out $GPU $k 2500 $N  >> ./results/dev_imageMat_invert.txt
#	done
#done


#for((k=1; k<=32; k*=2));
#do
#	echo running with k = $k
#	let "N = $k*56*32"

#	for((i=10; i<=1250; i*=5));
#	do
#		for((j=0; j<=15; j+=1));
#		do
#			echo iterations M = $i
#		        nvprof --log-file ./profiling/dev_imageMat_invert$k-$i.txt \
#				./blurgauss.out $GPU $k $i $N >> ./results/dev_imageMat_invert.txt
#		done	
#	done

#	for((j=0; j<=15; j+=1));
#	do
#		nvprof --log-file ./profiling/dev_imageMat_invert$k-2500.txt \
#			./blurgauss.out $GPU $k 2500 $N  >> ./results/dev_imageMat_invert.txt
#	done
#done
