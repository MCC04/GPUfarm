#!/bin/bash

rm -f ./results/dev_cos.txt
touch ./results/dev_cos.txt

rm -f ./profiling/dev_cos*.txt

BLUE='\033[1;34m'
NC='\033[0m'
#let GPU=2
let GPU=1

let BLOCK=512

#########
make clean
echo -e "${BLUE}compiling future...${NC}"
echo ""
make future

echo ***FUTURE_test***
for((j=0; j<=12; j+=1));
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
for((j=0; j<=12; j+=1));
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
for((j=0; j<=12; j+=1));
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

##########
make clean
echo -e "${BLUE}compiling emptyKer...${NC}"
echo ""
make empty

echo ***EMPTYKERNEL_test***
for((j=0; j<=12; j+=1));
do
	for((k=2; k<=32; k*=2));
	do
		echo running with k = $k
		let "N = $k*56*32"	
		nvprof --log-file ./profiling/dev_cos$k-0.txt ./bin/empty.out $GPU $BLOCK $k 0 $N >> ./results/dev_cos.txt
	done
done


