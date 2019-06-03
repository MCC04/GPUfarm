#!/bin/bash


rm -f ./results/dev_sp.txt
touch ./results/dev_sp.txt

rm -f ./profiling/dev_sp*.txt

BLUE='\033[1;34m'
NC='\033[0m'
#let GPU=2
let GPU=1

let BLOCK=64
let SM=64


#################
###### COS ######
#################

Miters=(10 50 250 1250 2500)

##### FUTURE #####
make clean
echo -e "${BLUE}compiling future...${NC}"
echo ""
make future

echo ***FUTURE_test***
for((j=0; j<10; j+=1));
do
	for((k=2; k<=32; k*=2));
	do
		let "N = $k*$SM*256"

		for m in "${Miters[@]}"
		do
			echo running with elements N = $N , iterations M = $m
			nvprof --log-file ./profiling/dev_fut_sp$N-$m.txt ./bin/future.out $GPU $BLOCK $SM $m $N \
								>> ./results/dev_sp.txt
		done
	done
done

##### STREAM #####
make clean
echo -e "${BLUE}compiling stream...${NC}"
echo ""
make stream

echo ***STREAM_test***
for((j=0; j<10; j+=1));
do
	for((k=2; k<=32; k*=2));
	do
		let "N = $k*$SM*256"

		for m in "${Miters[@]}"
		do
			echo running with elements N = $N , iterations M = $m
			nvprof --log-file ./profiling/dev_str_sp$N-$m.txt ./bin/stream.out $GPU $BLOCK $SM $m $N \
								>> ./results/dev_sp.txt
		done
	done
done

#################
#### COS LOW ####
#################

##### FUTURE #####
make clean
echo -e "${BLUE}compiling future low...${NC}"
echo ""
make futurelow

echo ***LOW PAR FUTURE_test***
for((j=0; j<10; j+=1));
do
	for((k=2; k<=32; k*=2));
	do
		let "N = $k*$SM*256"

		for m in "${Miters[@]}"
		do
			echo running with elements N = $N , iterations M = $m
			nvprof --log-file ./profiling/dev_fut_sp_low$N-$m.txt ./bin/futurelow.out $GPU $BLOCK $SM $m $N \
								>> ./results/dev_sp.txt
		done
	done
done

##### STREAM #####
make clean
echo -e "${BLUE}compiling stream low...${NC}"
echo ""
make streamlow 

echo ***LOW PAR STREAM_test***
for((j=0; j<10; j+=1));
do
	for((k=2; k<=32; k*=2));
	do		
		let "N = $k*$SM*256"

		for m in "${Miters[@]}"
		do
			echo running with elements N = $N , iterations M = $m
			nvprof --log-file ./profiling/dev_str_sp_low$N-$m.txt ./bin/streamlow.out $GPU $BLOCK $SM $m $N \
								>> ./results/dev_sp.txt
		done
	done
done


#################
#### MAT MUL ####
#################

Nmats=(16 32 64 128 256)

###### SQUARE MM ######
make clean
echo -e "${BLUE}compiling matmul...${NC}"
echo ""
make matmul
let "BLOCK=32"
echo ***MATMUL_test***

for((i=0; i<10; i+=1));
do
	echo iter = $i
	for((l=1; l<=16; l*=2));
	do		
		let "N = $l*64"

		for n in "${Nmats[@]}"
		do
			echo running with size N = $N , Nmat = $n
			nvprof --log-file ./profiling/dev_mm_sp$N-$n.txt \
								./bin/matmul.out $GPU $BLOCK $SM 1 $N $n \
								>> ./results/dev_sp.txt
		done
	done
done


###### SMALL SQUARE MM LOW ######
make clean
echo -e "${BLUE}compiling smallmatmul...${NC}"
echo ""
make smallmatmul
let "BLOCK=32"

echo ***SMALLMATMUL_test***


for((i=0; i<10; i+=1));
do
	echo iter = $i
	for((l=1; l<=16; l*=2));
	do		
		let "N = $l*64"

		for n in "${Nmats[@]}"
		do
			echo running with size N = $N , Nmat = $n
			nvprof --log-file ./profiling/dev_smm_sp$N-$n.txt \
								./bin/smallmatmul.out $GPU $BLOCK $SM 1 $N $n \
								>> ./results/dev_sp.txt
		done
	done
done


###### LOT SMALL SQUARE MM LOW ######
make clean
echo -e "${BLUE}compiling lot smallmatmul...${NC}"
echo ""
make smallmatmul
let "BLOCK=32"
echo ***LOTSMALLMATMUL_test***

lotOfMats=(	64 128 256 512 1024)

for((i=0; i<10; i+=1));
do
	echo iter = $i
	for((l=32; l>=2; l/=2));
	do		
		let "N = $l*2"

		for n in "${lotOfMats[@]}"
		do
			echo running with size N = $N , Nmat = $n
			nvprof --log-file ./profiling/dev_lsmm_sp$N-$n.txt \
								./bin/smallmatmul.out $GPU $BLOCK $SM 1 $N $n \
								>> ./results/dev_sp.txt
		done
	done
done



#####################
#### MAT MUL LOW ####
#####################

Nmats=(8 16 32 64 128)

######  SQUARE MM LOW ######
make clean
echo -e "${BLUE}compiling matmul LOW...${NC}"
echo ""
make matmullow
#let "BLOCK=4"
echo ***LOW PAR MATMUL_test***

for((i=0; i<10; i+=1));
do
	echo iter = $i
	for((l=1; l<=16; l*=2));
	do		
		let "N = $l*64"

		for n in "${Nmats[@]}"
		do
			echo running with size N = $N , Nmat = $n
			nvprof --log-file ./profiling/dev_mm_low_sp$N-$n.txt \
								./bin/matmullow.out $GPU $BLOCK $SM 1 $N $n 
								>> ./results/dev_sp.txt
		done
	done
done

###### SMALL SQUARE MM LOW ######
make clean
echo -e "${BLUE}compiling smallmatmul LOW...${NC}"
echo ""
make smallmatmullow
#let "BLOCK=4"
echo ***LOW PAR SMALLMATMUL_test***

for((i=0; i<10; i+=1));
do
	echo iter = $i
	for((l=32; l>=2; l/=2));
	do		
		let "N = $l*64"

		for n in "${Nmats[@]}"
		do
			echo running with size N = $N , Nmat = $n
			nvprof --log-file ./profiling/dev_smm_low_sp$N-$n.txt \
								./bin/smallmatmullow.out $GPU $BLOCK $SM 1 $N $n \
								>> ./results/dev_sp.txt
		done
	done
done



###### LOT SMALL SQUARE MM LOW ######
make clean
echo -e "${BLUE}compiling lot smallmatmul LOW...${NC}"
echo ""
make smallmatmullow
let "BLOCK=4"
echo ***LOW PAR LOTSMALLMATMUL_test***

lotOfMats=(	64 128 256 512 1024)

for((i=0; i<10; i+=1));
do
	echo iter = $i
	for((l=32; l>=2; l/=2));
	do		
		let "N = $l*2"

		for n in "${lotOfMats[@]}"
		do
			echo running with size N = $N , Nmat = $n
			nvprof --log-file ./profiling/dev_lsmm_low_sp$N-$n.txt \
								./bin/smallmatmullow.out $GPU $BLOCK $SM 1 $N $n \
								>> ./results/dev_sp.txt
		done
	done
done