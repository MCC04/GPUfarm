#!/bin/bash

rm -f ./results/host_cosMat_invert.txt
touch ./results/host_cosMat_invert.txt

rm -f ./profiling/host_cosMat_inv*.txt
#touch ./profiling/host_cosMat.txt

#ARGS="device nExec kerIters elemNum" >> host_cosMat.txt
#standard

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

for((k=2; k<=32; k*=2));
do
	echo running with k = $k
	let "N = $k*56*32"

	for((i=10; i<=1250; i*=5));
	do
		echo iterations M = $i
		for((j=0; j<=15; j+=1));
		do
			echo test num = $j
			nvprof --log-file ./profiling/host_cosMat_inv$k-$i.txt ./bin/hcosseq.out $k $i $N >> ./results/host_cosMat_invert.txt
		done
	done

	echo iterations M = 2500
	for((j=0; j<=15; j+=1));
	do
		echo test num = $j
		nvprof --log-file ./profiling/host_cosMat_inv$k-2500.txt ./bin/hcosseq.out $k 2500 $N  >> ./results/host_cosMat_invert.txt
	done
	
done

##########
make clean
echo -e "${BLUE}compiling hcospar...${NC}"
echo ""
make hcospar

echo ***HOST_COS_PAR_test***

for((k=2; k<=32; k*=2));
do
	echo running with k = $k
	let "N = $k*56*32"

	for((i=10; i<=1250; i*=5));
	do
		echo iterations M = $i
		for((j=0; j<=15; j+=1));
		do
			echo test num = $j
			nvprof --log-file ./profiling/host_cosMat_inv$k-$i.txt ./bin/hcospar.out $k $k $i $N >> ./results/host_cosMat_invert.txt
		done
	done

	echo iterations M = 2500
	for((j=0; j<=15; j+=1));
	do
		echo test num = $j
		nvprof --log-file ./profiling/host_cosMat_inv$k-2500.txt ./bin/hcospar.out $k $k 2500 $N  >> ./results/host_cosMat_invert.txt
	done
done

##########
make clean
echo -e "${BLUE}compiling hmmseq...${NC}"
echo ""
make hmmseq

echo ***HOST_MATMUL_SEQ_test***

for((j=1; j<=5; j+=1));
do
	let "M = $j*$Cb*8"
	let "K = $M+1"
	let "N = $M+2"
	echo running with M = $M , K = $K , N = $N

	echo number of matrices = $Cg
	for((l=0; l<=15; l+=1));
	do
		echo test num = $l
		nvprof --log-file ./profiling/host_cosMat_inv$j-$i.txt ./bin/hmmseq.out 4 $M $K $N $Cg >> ./results/host_cosMat_invert.txt
	done

	for((i=2; i<=8; i+=2));
	do
		let "Nmat = $i*$Cg"
		echo number of matrices = $Nmat
		for((l=0; l<=15; l+=1));
		do
			echo test num = $l
			nvprof --log-file ./profiling/host_cosMat_inv$j-$i.txt ./bin/hmmseq.out 4 $M $K $N $Nmat >> ./results/host_cosMat_invert.txt
		done
	done
done



##########
make clean
echo -e "${BLUE}compiling hmmpar...${NC}"
echo ""
make hmmpar

Nwrks=(1 4 16 32 56)

echo ***HOST_MATMUL_PAR_test***

for((j=1; j<=5; j+=1));
do
	#for((k=1; k<=32; k*=2));
	#do
		#echo running with k = $k
		#let "N = $k*56*32"
	let "M = $j*$Cb*8"
	let "K = $M+1"
	let "N = $M+2"
	let "Nwrks = 1"
	echo running with M = $M , K = $K , N = $N
	
	
	#echo Nmat = $Cg
	#echo workers = $Nwrks
	#nvprof --log-file ./profiling/host_cosMat$j-$i.txt ./bin/hmmpar.out 4 $M $K $N $Cg $Nwrks >> ./results/host_cosMat.txt
	#for((i=1; i<=5; i+=1));
	let cnt=1
	for n in "${Nwrks[@]}"
	do
		let Nmat=$cnt*$Cg
		#let "Nwrks = $Nwrks * 2"
		let mxw=$Nmat/$n #= Cb
	
		echo Nmat=$Nmat
		echo workers=$n
		echo mxw=$mxw
		for((i=0; i<=15; i+=1));
		do
			echo test num = $i
			nvprof --log-file ./profiling/host_cosMat_inv$j-$cnt.txt ./bin/hmmpar.out 4 $M $K $N $mxw $n >> ./results/host_cosMat_invert.txt
		done #let "Nwrks = $Nwrks*2"
		let cnt=$cnt+1
	done
done



