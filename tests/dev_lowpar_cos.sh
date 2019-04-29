#!/bin/bash

rm -f ./results/dev_lowpar_cos.txt
touch ./results/dev_lowpar_cos.txt

rm -f ./profiling/dev_lowpar_cos*.txt

BLUE='\033[1;34m'
NC='\033[0m'
#let GPU=2
let GPU=1

let BLOCK=16

##############
make clean
echo -e "${BLUE}compiling future low...${NC}"
echo ""
make futurelow

echo ***LOW PAR FUTURE_test***
for((j=0; j<=15; j+=1));
do
	for((k=2; k<=32; k*=2));
	do
		echo running with k = $k
		let "N = $k*56*32"
	
		for((i=10; i<=1250; i*=5));
		do
			echo iterations M = $i
			nvprof --log-file ./profiling/dev_lowpar_cos$k-$i.txt ./bin/futurelow.out $GPU $BLOCK $k $i $N >> ./results/dev_lowpar_cos.txt
		done
		nvprof --log-file ./profiling/dev_lowpar_cos$k-2500.txt ./bin/futurelow.out $GPU $BLOCK $k 2500 $N  >> ./results/dev_lowpar_cos.txt
	done
done

##########
make clean
echo -e "${BLUE}compiling stream low...${NC}"
echo ""
make streamlow 

echo ***LOW PAR STREAM_test***
for((j=0; j<=15; j+=1));
do
	for((k=2; k<=32; k*=2));
	do
		echo running with k = $k
		let "N = $k*56*32"
	
		for((i=10; i<=1250; i*=5));
		do
			echo iterations M = $i
			nvprof --log-file ./profiling/dev_lowpar_cos$k-$i.txt ./bin/streamlow.out $GPU $BLOCK $k $i $N >> ./results/dev_lowpar_cos.txt
		done
		nvprof --log-file ./profiling/dev_lowpar_cos$k-2500.txt ./bin/streamlow.out $GPU $BLOCK $k 2500 $N  >> ./results/dev_lowpar_cos.txt
	done
done

##########
make clean
echo -e "${BLUE}compiling managed low...${NC}"
echo ""
make managedlow

echo ***LOW PAR MANAGED_test***
for((j=0; j<=15; j+=1));
do
	for((k=2; k<=32; k*=2));
	do
		echo running with k = $k
		let "N = $k*56*32"
	
		for((i=10; i<=1250; i*=5));
		do
			echo iterations M = $i
			nvprof --log-file ./profiling/dev_lowpar_cos$k-$i.txt ./bin/managedlow.out $GPU $BLOCK $k $i $N >> ./results/dev_lowpar_cos.txt
		done
		nvprof --log-file ./profiling/dev_lowpar_cos$k-2500.txt ./bin/managedlow.out $GPU $BLOCK $k 2500 $N  >> ./results/dev_lowpar_cos.txt
	done
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








