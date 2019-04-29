#!/bin/bash

rm -f ./results/host_mat.txt
touch ./results/host_mat.txt

#rm -f ./profiling/host_mat*.txt

#let "Cb=32"
let "Cb=16"
#let "Cg=56"
BLUE='\033[1;34m'
NC='\033[0m'

Nmats=(4 16 32 64 128)


##########
#Nmats=(4 16 64 128 256)

make clean
echo -e "${BLUE}compiling hmmseq...${NC}"
echo ""
make hmmseq

echo ***HOST_MATMUL_SEQ_test***


for((l=0; l<=12; l+=1));
do
	echo test num = $l
	for((j=1; j<=16; j*=2));
	do
		let "M = $j*$Cb"		
		let "K = $M/4"
		let "N = $M+2"
		echo running with M = $M , K = $K , N = $N


		#echo number of matrices = $Cg
		#nvprof --log-file ./profiling/host_mat$j-$i.txt ./bin/hmmseq.out 4 $M $K $N $Cg >> ./results/host_mat.txt
		#for((i=2; i<=8; i+=2));
		for n in "${Nmats[@]}"
		do
			#let "Nmat = $i*$Cg"
			echo number of matrices = $n
			#nvprof --log-file ./profiling/host_mat$j-$i.txt 
			./bin/hmmseq.out 4 $M $K $N $n >> ./results/host_mat.txt
		done
	done
done



##########
make clean
echo -e "${BLUE}compiling hmmpar...${NC}"
echo ""
make hmmpar


#Nmats=(4 16 32 64 128)

Nwrks=(1 4 16 32 64)
#Nmats=(1 10 25 50 100)
#Nmats=(4 16 64 128 256)
let mxw=4

echo ***HOST_MATMUL_PAR_test***
echo mxw=$mxw
for((i=0; i<=12; i+=1));
do
	echo test num = $i
	for((j=1; j<=16; j*=2));
	do
		#let "M = $j*$Cb*8"
		let "M = $j*$Cb"
		let "K = $M/4"
		let "N = $M+2"
		let "Nwrks = 1"
		#let cnt=1
		echo running with M = $M , K = $K , N = $N				

		for n in "${Nwrks[@]}" #, "${Nmats[@]}"
		do			
			#let Nmat=$n*4
			echo Nmat=$mxw*$n , workers=$n #, mxw=$mxw
		
			#nvprof --log-file ./profiling/host_mat$j-$n.txt 
			./bin/hmmpar.out 4 $M $K $N $mxw $n >> ./results/host_mat.txt
			#let cnt=$cnt+1
		done
	done
done



