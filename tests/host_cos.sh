#!/bin/bash

rm -f ./results/host_cos.txt
touch ./results/host_cos.txt

#rm -f ./profiling/host_cos*.txt

let "Cb=32"
let "Cg=56"
BLUE='\033[1;34m'
NC='\033[0m'

########
make clean
echo -e "${BLUE}compiling hcosseq...${NC}"
echo ""
make hcosseq

echo ***HOST_COS_SEQ_test***
for((j=0; j<=12; j+=1));
do
	echo test num = $j
	for((k=2; k<=32; k*=2));
	do
		echo running with k = $k
		let "N = $k*56*32"
	
		for((i=10; i<=1250; i*=5));
		do
			echo iterations M = $i
			./bin/hcosseq.out $k $i $N >> ./results/host_cos.txt
		done
		echo iterations M = 2500
		./bin/hcosseq.out $k 2500 $N  >> ./results/host_cos.txt
	done
done

##########
make clean
echo -e "${BLUE}compiling hcospar...${NC}"
echo ""
make hcospar

echo ***HOST_COS_PAR_test***
for((j=0; j<=12; j+=1));
do
	echo test num = $j
	for((k=2; k<=32; k*=2));
	do
		echo running with k = $k
		let "N = $k*56*32"
	
		for((i=10; i<=1250; i*=5));
		do
			echo iterations M = $i
			./bin/hcospar.out $k $k $i $N >> ./results/host_cos.txt
		done
		echo iterations M = 2500
		./bin/hcospar.out $k $k 2500 $N  >> ./results/host_cos.txt
	done
done

##########
