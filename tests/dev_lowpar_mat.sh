#!/bin/bash

rm -f ./results/dev_lowpar_mat.txt
touch ./results/dev_lowpar_mat.txt

rm -f ./profiling/dev_lowpar_mat*.txt

BLUE='\033[1;34m'
NC='\033[0m'

############################
####DEVICE IMAGE MATMUL#####
############################



let GPU=1
#let GPU=3

#Nmats=(1 10 25 50 100)
#Nmats=(4 16 64 128 256)
Nmats=(8 16 32 64 128)


############
make clean
echo -e "${BLUE}compiling matmul LOW...${NC}"
echo ""
make matmullow
let "BLOCK=4"
#let "K = $BLOCK"
echo ***LOW PAR MATMUL_test***

#Nmats=(1 10 25 50 100)
for((i=0; i<=12; i+=1));
do
	echo iter = $i
	for((l=1; l<=16; l*=2));
	do		
		let "M = $l*16"
		let "K = $M/4"
		let "N = $M+2"
		echo running with M = $M , K = $K , N = $N 

		for n in "${Nmats[@]}"
		do
			echo Nmat=$n
			nvprof --log-file ./profiling/dev_lowpar_mat$l-$n.txt ./bin/matmullow.out $GPU $BLOCK 4 $M $K $N $n >> ./results/dev_lowpar_mat.txt

		done
	done
done

############
make clean
echo -e "${BLUE}compiling smallmatmul LOW...${NC}"
echo ""
make smallmatmullow
let "BLOCK=4"
#let "K = $BLOCK"
echo ***LOW PAR SMALLMATMUL_test***

#lotOfMats=(	64 128 256 512 1024)
#Nmats=(1 10 25 50 100)
for((i=0; i<=12; i+=1));
do
	echo iter = $i
	for((l=32; l>=2; l/=2));
	do		
		let "M = $l"
		let "K = $l+1"
		let "N = $l+2"
		echo running with M = $M , K = $K , N = $N 

		for n in "${Nmats[@]}"
		do
			echo Nmat=$n
			nvprof --log-file ./profiling/dev_lowpar_mat$l-$n.txt ./bin/smallmatmullow.out $GPU $BLOCK 4 $M $K $N $n >> ./results/dev_lowpar_mat.txt

		done
	done
done






############
make clean
echo -e "${BLUE}compiling smallmatmul LOW...${NC}"
echo ""
make smallmatmullow
let "BLOCK=4"
#let "K = $BLOCK"
echo ***LOW PAR LOTSMALLMATMUL_test***

lotOfMats=(	64 128 256 512 1024)
#Nmats=(1 10 25 50 100)
for((i=0; i<=12; i+=1));
do
	echo iter = $i
	for((l=32; l>=2; l/=2));
	do		
		let "M = $l"
		let "K = $l+1"
		let "N = $l+2"
		echo running with M = $M , K = $K , N = $N 

		for n in "${lotOfMats[@]}"
		do
			echo Nmat=$n
			nvprof --log-file ./profiling/dev_lowpar_mat$l-$n.txt ./bin/smallmatmullow.out $GPU $BLOCK 4 $M $K $N $n >> ./results/dev_lowpar_mat.txt

		done
	done
done


##########
make clean
echo -e "${BLUE}compiling blurbox low...${NC}"
echo ""
make blurboxlow

echo ***LOW PAR BLURBOX_test***

let BLOCK=4
echo "block size set to $BLOCK"
for((i=0; i<=12; i+=1));
do
	echo running test = $i
	nvprof --log-file ./profiling/dev_lowpar_mat_$BLOCK-$i.txt ./bin/blurboxlow.out $GPU $BLOCK 4  >> ./results/dev_lowpar_mat.txt                   
done

#let BLOCK=1024
#echo "block size set to $BLOCK"
#for((i=0; i<=12; i+=1));
#do                
#	echo running test = $i
#	nvprof --log-file ./profiling/dev_lowpar_mat_$BLOCK-$i.txt ./bin/blurbox.out $GPU $BLOCK 4  >> ./results/dev_lowpar_mat.txt
#done

