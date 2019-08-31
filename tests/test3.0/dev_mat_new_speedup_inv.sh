#!/bin/bash


rm -f ./results/dev_cos_sp_inv.txt
touch ./results/dev_cos_sp_inv.txt

rm -f ./profiling/dev_cos_sp_inv*.txt

BLUE='\033[1;34m'
NC='\033[0m'
#let GPU=2
let GPU=0

let BLOCK=64
let SM=56


#################
###### COS ######
#################

#Miters=(10 50 250 1250 2500)
Miters=(64 128 256 512 1024)
let K_ex=32

##### FUTURE #####
#make clean
#echo -e "${BLUE}compiling future...${NC}"
#echo ""
#make future

#echo ***FUTURE_test***
#for((j=0; j<10; j+=1));
#do
#	for((k=2; k<=32; k*=2));
#	do
#		let "N = $k*$SM*$SM*BLOCK"

#		for m in "${Miters[@]}"
#		do
#			echo running with elements N = $N , iterations M = $m
#			nvprof --log-file ./profiling/dev_fut_sp$N-$m.txt ./bin/future.out $GPU $BLOCK $SM $m $N \
#								>> ./results/dev_cos_sp_inv.txt
#		done
#	done
#done

##### FUTURE LOW #####
#make clean
#echo -e "${BLUE}compiling future low...${NC}"
#echo ""
#make futurelow

#echo ***LOW PAR FUTURE_test***
#for((j=0; j<10; j+=1));
#do
#	for((k=2; k<=32; k*=2));
#	do
#		let "N = $k*$SM*$SM*BLOCK"
#
#		for m in "${Miters[@]}"
#		do
#			echo running with elements N = $N , iterations M = $m
#			nvprof --log-file ./profiling/dev_fut_sp_low$N-$m.txt ./bin/futurelow.out $GPU $BLOCK $SM $m $N \
#								>> ./results/dev_cos_sp_inv.txt
#		done
#	done
#done

##### STREAM #####
make clean
echo -e "${BLUE}compiling stream...${NC}"
echo ""
make stream

echo ***STREAM_test***

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
			nvprof --log-file ./profiling/dev_str_sp_inv$N-$m.txt ./bin/stream.out $GPU $BLOCK $K_ex $m $N \
							>> ./results/dev_cos_sp_inv.txt
		done
	done
done


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
			nvprof --log-file ./profiling/dev_str_sp_inv_low$N-$m.txt ./bin/streamlow.out $GPU $BLOCK $SK_ex $m $N \ 
							>> ./results/dev_cos_sp_inv.txt
		done
	done
done


#################
#### MAT MUL ####
#################
let BLOCK=32
let iters=8
#Nmats=(16 32 64 128 256)
Nmats=(32 64 128 256 512)

###### SQUARE MM ######
make clean
echo -e "${BLUE}compiling matmul...${NC}"
echo ""
make matmul
#let "BLOCK=32"
echo ***MATMUL_test***


for n in "${Nmats[@]}"
do		
	#for((l=1; l<=16; l*=2));
	for((l=1; l<=5; l+=1));
	do		
		let "N = $l*$SM"
		echo running with size N = $N , Nmat = $n	

		for((i=0; i<10; i+=1));
		do
			echo iter = $i
			nvprof --log-file ./profiling/dev_mm_sp_inv$N-$n.txt \
							./bin/matmul.out $GPU $BLOCK $iters 1 $N $n \
							>> ./results/dev_cos_sp_inv.txt
		done
	done
done

######  SQUARE MM LOW ######
make clean
echo -e "${BLUE}compiling matmul LOW...${NC}"
echo ""
make matmullow
#let "BLOCK=4"
echo ***LOW PAR MATMUL_test***


for n in "${Nmats[@]}"
do
	#for((l=1; l<=16; l*=2));
	for((l=1; l<=5; l+=1));
	do		
		let "N = $l*$SM"			
		echo running with size N = $N , Nmat = $n

		for((i=0; i<10; i+=1));
		do
			echo iter = $i

			nvprof --log-file ./profiling/dev_mm_low_sp_inv$N-$n.txt \
							./bin/matmullow.out $GPU $BLOCK $iters 1 $N $n \
							>> ./results/dev_cos_sp_inv.txt
		done
	done
done




###### SQUARE SMALL MM ######
make clean
echo -e "${BLUE}compiling matmul...${NC}"
echo ""
make matmul
#let "BLOCK=32"
echo ***MATMUL_test***


for n in "${Nmats[@]}"
do
	#for((l=1; l<=16; l*=2));
	for((l=1; l<=5; l+=1));
	do		
		let "N = $l*$SM"		
		echo running with size N = $N , Nmat = $n

		for((i=0; i<10; i+=1));
		do
			echo iter = $i

			nvprof --log-file ./profiling/dev_smm_sp_inv$N-$n.txt \
							./bin/matmul.out $GPU $BLOCK $n 1 $N $n \ 
							>> ./results/dev_cos_sp_inv.txt 
							#chunk = Nmats/Nmats = 1
		done
	done
done

######  SQUARE SMALL MM LOW ######
make clean
echo -e "${BLUE}compiling matmul LOW...${NC}"
echo ""
make matmullow
#let "BLOCK=4"
echo ***LOW PAR MATMUL_test***


for n in "${Nmats[@]}"
do
	#for((l=1; l<=16; l*=2));
	for((l=1; l<=5; l+=1));
	do		
		let "N = $l*$SM"		
		echo running with size N = $N , Nmat = $n
		for((i=0; i<10; i+=1));
		do
			echo iter = $i
			nvprof --log-file ./profiling/dev_smm_low_sp_inv$N-$n.txt \
							./bin/matmullow.out $GPU $BLOCK $n 1 $N $n \ 
							>> ./results/dev_cos_sp_inv.txt 
							#chunk = N/N = 1
		done
	done
done




###### LOT SMALL SQUARE MM LOW ######
#make clean
#echo -e "${BLUE}compiling lot smallmatmul...${NC}"
#echo ""
#make matmul
#echo ***LOTSMALLMATMUL_test***

#lotOfMats=(	64 128 256 512 1024)

#for((i=0; i<10; i+=1));
#do
#	echo iter = $i
#	for n in "${lotOfMats[@]}"
#	do
#		for((l=32; l>=2; l/=2));
#		do		
#			let "N = $l*2"		
#			echo running with size N = $N , Nmat = $n

#			nvprof --log-file ./profiling/dev_lsmm_sp$N-$n.txt \
#								./bin/matmul.out $GPU $BLOCK $n 1 $N $n \ 
#								>> ./results/dev_cos_sp_inv.txt
#		done
#	done
#done

###### LOT SMALL SQUARE MM LOW ######
#make clean
#echo -e "${BLUE}compiling lot smallmatmul LOW...${NC}"
#echo ""
#make matmullow
#echo ***LOW PAR LOTSMALLMATMUL_test***

#for((i=0; i<10; i+=1));
#do
#	echo iter = $i
#	for n in "${lotOfMats[@]}"
#	do
#		for((l=32; l>=2; l/=2));
#		do		
#			let "N = $l*2"		
#			echo running with size N = $N , Nmat = $n

#			nvprof --log-file ./profiling/dev_lsmm_low_sp$N-$n.txt \
#								./bin/matmullow.out $GPU $BLOCK $n 1 $N $n \ 
#								>> ./results/dev_cos_sp_inv.txt
#		done
#	done
#done