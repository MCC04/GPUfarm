#!/bin/bash

rm -f ./results/autosched.txt
touch ./results/autosched.txt

rm -f ./profiling/autosched*.txt

BLUE='\033[1;34m'
NC='\033[0m'
#let GPU=2
let GPU=1

let BLOCK=64
let SM=56

#########
make clean
echo -e "${BLUE}compiling autosched...${NC}"
echo ""
make autosched

echo ***AUTOSCHED_test***
for((j=0; j<=12; j+=1));
do
	for((k=8; k<=128; k*=2));
	do
		echo running with k = $k
		let "N = $k*$SM*$BLOCK"
		let "buffSize = $N/$k"
	
		for((i=10; i<=1250; i*=5));
		do
			echo iterations M = $i
			#nvprof ./bin/autosched.out GPU BLOCK K_str M_iter N_elem buff_Size startP startQ
			nvprof --log-file ./profiling/autosched$k-$i.txt ./bin/autosched.out $GPU $BLOCK 4 $i $N $buffSize 0.3 0.7 >> ./results/autosched.txt
		done
		nvprof --log-file ./profiling/autosched$k-2500.txt ./bin/autosched.out $GPU $BLOCK 4 2500 $N $buffSize 0.3 0.7 >> ./results/autosched.txt
	done
done



