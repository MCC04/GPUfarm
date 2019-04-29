#!/bin/bash

rm -f ./results/dev_cos_invert.txt
touch ./results/dev_cos_invert.txt

rm -f ./profiling/dev_cos_inv*.txt

BLUE='\033[1;34m'
NC='\033[0m'
#let GPU=2
let GPU=1
let BLOCK=512

###########
make clean

echo -e "${BLUE}compiling future...${NC}"
echo ""
make future
echo ***FUTURE_test***
for((k=2; k<=32; k*=2));
do
	echo running with k = $k
	let "N = $k*56*32"

	for((i=10; i<=1250; i*=5));
	do
		for((j=0; j<=12; j+=1));
		do
			echo iterations M = $i
			nvprof --log-file ./profiling/dev_cos_inv$k-$i.txt ./bin/future.out $GPU $BLOCK $k $i $N >> ./results/dev_cos_invert.txt
		done		
	done
	
	for((j=0; j<=12; j+=1));
	do
		nvprof --log-file ./profiling/dev_cos_inv$k-2500.txt ./bin/future.out $GPU $BLOCK $k 2500 $N  >> ./results/dev_cos_invert.txt
	done
done
##########
make clean
echo -e "${BLUE}compiling stream...${NC}"
echo ""
make stream

echo ***STREAM_test***
for((k=2; k<=32; k*=2));
do
	echo running with k = $k
	let "N = $k*56*32"

	for((i=10; i<=1250; i*=5));
	do
		for((j=0; j<=12; j+=1));
		do
			echo iterations M = $i
			nvprof --log-file ./profiling/dev_cos_inv$k-$i.txt ./bin/stream.out $GPU $BLOCK $k $i $N >> ./results/dev_cos_invert.txt
		done
	
	done
	for((j=0; j<=12; j+=1));
	do
		nvprof --log-file ./profiling/dev_cos_inv$k-2500.txt ./bin/stream.out $GPU $BLOCK $k 2500 $N  >> ./results/dev_cos_invert.txt
	done
done

##########
make clean
echo -e "${BLUE}compiling managed...${NC}"
echo ""
make managed

echo ***MANAGED_test***
for((k=2; k<=32; k*=2));
do
	echo running with k = $k
	let "N = $k*56*32"

	for((i=10; i<=1250; i*=5));
	do
		for((j=0; j<=12; j+=1));
		do
			echo iterations M = $i
			nvprof --log-file ./profiling/dev_cos_inv$k-$i.txt ./bin/managed.out $GPU $BLOCK $k $i $N >> ./results/dev_cos_invert.txt
		done	
	done
	for((j=0; j<=12; j+=1));
	do
		nvprof --log-file ./profiling/dev_cos_inv$k-2500.txt ./bin/managed.out $GPU $BLOCK $k 2500 $N  >> ./results/dev_cos_invert.txt
	done
done
