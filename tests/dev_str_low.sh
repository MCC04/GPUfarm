#!/bin/bash


rm -f ./results/dev_sp_str_low.txt
touch ./results/dev_sp_str_low.txt

rm -f ./profiling/dev_sp_inv*.txt

BLUE='\033[1;34m'
NC='\033[0m'
#let GPU=2
let GPU=0

let BLOCK=64
let SM=56


#################
###### COS ######
#################

Miters=(64 128 256 512 1024)
let K_ex=32


##### STREAM LOW #####
make clean
echo -e "${BLUE}compiling stream low...${NC}"
echo ""
make streamlow 

echo ***LOW STREAM_test***

for((k=1; k<=16; k*=2));
do		
	let "N = $k*$SM*$K_ex*$BLOCK"

	for m in "${Miters[@]}"
	do
		echo running with elements N = $N , iterations M = $m
		echo iter number:
		for((j=0; j<10; j+=1));
		do
			echo $j
			nvprof --log-file ./profiling/dev_str_sp_inv_low$N-$m.txt ./bin/streamlow.out $GPU $BLOCK $K_ex $m $N \ 
                                >> ./results/dev_sp_str_low.txt
		done
	done
done

