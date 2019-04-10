#!/bin/bash


############################
#########DEVICE COS#########
############################
rm -f ./results/low_par.txt
touch ./results/low_par.txt

rm -f ./profiling/low_par.txt
#touch ./profiling/dev_cos.txt

#ARGS="device nExec kerIters elemNum" >> dev_cos.txt
#standard

BLUE='\033[1;34m'
NC='\033[0m'

let GPU=1
let BLOCK=32


make clean
echo -e "${BLUE}compiling future...${NC}"
echo ""
make future

echo ***FUTURE_test***
for((j=0; j<=15; j+=1));
do
	for((k=2; k<=32; k*=2));
	do
		echo running with k = $k
		let "N = $k*56*32"
	
		for((i=10; i<=1250; i*=5));
		do
			echo iterations M = $i
			nvprof --log-file ./profiling/dev_cos$k-$i.txt ./bin/future.out $GPU $BLOCK $k $i $N >> ./results/dev_cos.txt
		done
		nvprof --log-file ./profiling/dev_cos$k-2500.txt ./bin/future.out $GPU $BLOCK $k 2500 $N  >> ./results/dev_cos.txt
	done
done

##########
make clean
echo -e "${BLUE}compiling stream...${NC}"
echo ""
make stream 

echo ***STREAM_test***
for((j=0; j<=15; j+=1));
do
	for((k=2; k<=32; k*=2));
	do
		echo running with k = $k
		let "N = $k*56*32"
	
		for((i=10; i<=1250; i*=5));
		do
			echo iterations M = $i
			nvprof --log-file ./profiling/dev_cos$k-$i.txt ./bin/stream.out $GPU $BLOCK $k $i $N >> ./results/dev_cos.txt
		done
		nvprof --log-file ./profiling/dev_cos$k-2500.txt ./bin/stream.out $GPU $BLOCK $k 2500 $N  >> ./results/dev_cos.txt
	done
done

##########
make clean
echo -e "${BLUE}compiling managed...${NC}"
echo ""
make managed

echo ***MANAGED_test***
for((j=0; j<=15; j+=1));
do
	for((k=2; k<=32; k*=2));
	do
		echo running with k = $k
		let "N = $k*56*32"
	
		for((i=10; i<=1250; i*=5));
		do
			echo iterations M = $i
			nvprof --log-file ./profiling/dev_cos$k-$i.txt ./bin/managed.out $GPU $BLOCK $k $i $N >> ./results/dev_cos.txt
		done
		nvprof --log-file ./profiling/dev_cos$k-2500.txt ./bin/managed.out $GPU $BLOCK $k 2500 $N  >> ./results/dev_cos.txt
	done
done


############################
####DEVICE IMAGE MATMUL#####
############################

make clean
echo -e "${BLUE}compiling matmul...${NC}"
echo ""
make matmul

let BLOCK=8
let DIM=32
echo ***MATMUL_test***
for((i=0; i<=15; i+=1));
do
	for((l=1; l<=5; l+=1));
	do		
		let "M = $l*$DIM*8"
		let "K = $M+1"
		let "M = $M+2"
		echo running with M = $M , K = $K , N = $N 
	
		for((j=1; j<=5; j+=1));
		do
			let "Nmat = $j*56"
			echo number of matrices = $Nmat
			nvprof --log-file ./profiling/dev_imageMat$l-$j.txt ./bin/matmul.out $GPU $BLOCK 4 $M $K $N $Nmat >> ./results/dev_imageMat.txt
		done
		#nvprof --log-file ./profiling/dev_imageMat$l-2500.txt ./matmul.out $GPU $BLOCK $M 2500 $N  >> ./results/dev_imageMat.txt
	done
done

##########
make clean
echo -e "${BLUE}compiling blurbox...${NC}"
echo ""
make blurbox

echo ***BLURBOX_test***
for((i=0; i<=15; i+=1));
do
	#for((k=2; k<=32; k*=2));
	#do
		echo running with i = $i
		#let "N = $k*56*32"
	
		#for((i=10; i<=1250; i*=5));
		#do
			#echo iterations M = $i
		nvprof --log-file ./profiling/dev_imageMat_$BLOCK-$i.txt ./bin/blurbox.out $GPU $BLOCK 4  >> ./results/dev_imageMat_512.txt
                        
                        #nvprof --log-file ./profiling/dev_imageMat_1024$i.txt ./bin/blurbox.out $GPU 1024 4  >> ./results/dev_imageMat_1024.txt
		#done
		#nvprof --log-file ./profiling/dev_imageMat$k-2500.txt ./blurbox.out $GPU 512   >> ./results/dev_imageMat.txt
	#done
done

#echo ***BLURGAUSS_test***
#for((j=0; j<=15; j+=1));
#do
#	for((k=2; k<=32; k*=2));
#	do
#		echo running with k = $k
#		let "N = $k*56*32"
#	
#		for((i=10; i<=1250; i*=5));
#		do
#			echo iterations M = $i
#                        nvprof --log-file ./profiling/dev_imageMat$k-$i.txt ./blurgauss.out 1 512 >> ./results/dev_imageMat.txt
#		done
#		nvprof --log-file ./profiling/dev_imageMat$k-2500.txt ./blurgauss.out 1 512 >> ./results/dev_imageMat.txt
#	done
#done








