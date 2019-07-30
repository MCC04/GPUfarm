#!/bin/bash

rm -f ./results/dev_mat_invert.txt
touch ./results/dev_mat_invert.txt

rm -f ./profiling/dev_mat_inv*.txt

BLUE='\033[1;34m'
NC='\033[0m'
#let GPU=2
let GPU=1


#Nmats=(1 10 25 50 100)
#Nmats=(4 16 64 128 256)
Nmats=(8 16 32 64 128)


############
make clean
echo -e "${BLUE}compiling matmul...${NC}"
echo ""
make matmul
let "BLOCK=32"

echo ***MATMUL_test***
#for((l=2; l<=32; l*=2));
for((l=1; l<=16; l*=2));
do		
	#let "M = $l*$BLOCK*8"
	let "M = $l*16"
	#let "K = $M+1"
	let "K = $M/4"
	let "N = $M+2"
	echo running with M = $M , K = $K , N = $N 

	for n in "${Nmats[@]}"
	do
		echo Nmat=$n
		for((i=0; i<=12; i+=1));
		do
			echo iter = $i

			nvprof --log-file ./profiling/dev_mat_inv$l-$n.txt ./bin/matmul.out $GPU $BLOCK 4 $M $K $N $n >> ./results/dev_mat_invert.txt
		done
	done
done

############
make clean
echo -e "${BLUE}compiling smallmatmul...${NC}"
echo ""
make smallmatmul
let "BLOCK=32"
echo ***SMALLMATMUL_test***

#Nmats=(1 10 25 50 100)

for((l=1; l<=16; l*=2));
do		
	let "M = $l*$16"
	let "K = $M/4"
	let "N = $M+2"
	echo running with M = $M , K = $K , N = $N 

	for n in "${Nmats[@]}"
	do
		echo Nmat=$n
		for((i=0; i<=12; i+=1));
		do
			echo iter = $i
			nvprof --log-file ./profiling/dev_mat_inv$l-$n.txt ./bin/smallmatmul.out $GPU $BLOCK 4 $M $K $N $n >> ./results/dev_mat_invert.txt

		done
	done
done


############
make clean
echo -e "${BLUE}compiling smallmatmul...${NC}"
echo ""
make smallmatmul
let "BLOCK=32"
#let "K = $BLOCK"
echo ***LOTSMALLMATMUL_test***

lotOfMats=(	64 128 256 512 1024)
#Nmats=(1 10 25 50 100)

	
for((l=32; l>=2; l/=2));
do		
	let "M = $l"
	let "K = $l+1"
	let "N = $l+2"
	echo running with M = $M , K = $K , N = $N 

	for n in "${lotOfMats[@]}"
	do
		echo Nmat=$n
		for((i=0; i<=12; i+=1));
		do
			echo iter = $i
			nvprof --log-file ./profiling/dev_mat$l-$n.txt ./bin/smallmatmul.out $GPU $BLOCK 4 $M $K $N $n >> ./results/dev_mat_invert.txt

		done
	done
done

###########
#make clean
#echo -e "${BLUE}compiling matmul...${NC}"
#echo ""
#make matmul
#let "BLOCK=32"
#echo ***MATMUL_test***

#for((l=1; l<=5; l+=1));
#do		
#	let "M = $l*$BLOCK*8"
#	let "K = $M+1"
#	let "N = $M+2"
#	echo running with M = $M , K = $K , N = $N 

#	for((j=1; j<=5; j+=1));
#	do
#		let "Nmat = $j*56"
#		echo number of matrices = $Nmat
#		for((i=0; i<=12; i+=1));
#		do
#			echo iter = $i

#			nvprof --log-file ./profiling/dev_mat_inv$l-$j.txt ./bin/matmul.out $GPU $BLOCK 4 $M $K $N $Nmat >> ./results/dev_mat_invert.txt
#		done
#	done
#done

############