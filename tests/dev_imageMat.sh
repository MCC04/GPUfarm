#!/bin/bash

rm -f ./results/dev_mat.txt
touch ./results/dev_mat.txt

rm -f ./profiling/dev_mat*.txt

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
#let "K = $BLOCK"
echo ***MATMUL_test***

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
			nvprof --log-file ./profiling/dev_mat$l-$n.txt ./bin/matmul.out $GPU $BLOCK 4 $M $K $N $n >> ./results/dev_mat.txt

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
echo ***SMALLMATMUL_test***

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
			nvprof --log-file ./profiling/dev_mat$l-$n.txt ./bin/smallmatmul.out $GPU $BLOCK 4 $M $K $N $n >> ./results/dev_mat.txt

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
			nvprof --log-file ./profiling/dev_mat$l-$n.txt ./bin/smallmatmul.out $GPU $BLOCK 4 $M $K $N $n >> ./results/dev_mat.txt

		done
	done
done





#for((i=0; i<=12; i+=1));
#do
#	echo iter = $i
#	for((l=1; l<=5; l+=1));
#	do		
#		let "M = $l*$BLOCK*8"
#		let "K = $M+1"
#		let "N = $M+2"
#		echo running with M = $M , K = $K , N = $N 

#		for((j=1; j<=5; j+=1));
#		do
#			let "Nmat = $j*56"
#			echo number of matrices = $Nmat			
#			nvprof --log-file ./profiling/dev_mat$l-$j.txt ./bin/smallmatmul.out $GPU $BLOCK 4 $M $K $N $Nmat >> ./results/dev_mat.txt
#		done
#	done
#done

##########
make clean
echo -e "${BLUE}compiling blurbox...${NC}"
echo ""
make blurbox

echo ***BLURBOX_test***

let BLOCK=512
echo "block size set to $BLOCK"
for((i=0; i<=12; i+=1));
do
	echo running test = $i
	nvprof --log-file ./profiling/dev_mat$BLOCK-$i.txt ./bin/blurbox.out $GPU $BLOCK 4  >> ./results/dev_mat.txt                   
done

let BLOCK=1024
echo "block size set to $BLOCK"
for((i=0; i<=12; i+=1));
do                
	echo running test = $i
	nvprof --log-file ./profiling/dev_mat$BLOCK-$i.txt ./bin/blurbox.out $GPU $BLOCK 4  >> ./results/dev_mat.txt
done

##########
#amek clean
#echo "compiling blurgauss executable..."
#echo ""
#make blurgauss
#echo ***BLURGAUSS_test***
#for((j=0; j<=12; j+=1));
#do
#	for((k=2; k<=32; k*=2));
#	do
#		echo running with k = $k
#		let "N = $k*56*32"
#	
#		for((i=10; i<=1250; i*=5));
#		do
#			echo iterations M = $i
#                        nvprof --log-file ./profiling/dev_mat$k-$i.txt ./blurgauss.out $GPU $BLOCK >> ./results/dev_mat.txt
#		done
#		nvprof --log-file ./profiling/dev_mat$k-2500.txt ./blurgauss.out $GPU $BLOCK >> ./results/dev_mat.txt
#	done
#done
