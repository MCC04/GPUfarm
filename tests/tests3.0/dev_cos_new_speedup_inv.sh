#!/bin/bash


rm -f ./results/dev_cos_sp_inv.txt
touch ./results/dev_cos_sp_inv.txt

#rm -f ./profiling/dev_cos_sp_inv*.txt

BLUE='\033[1;34m'
NC='\033[0m'
#let GPU=2
let GPU=0

let BLOCK=1024
let SM=56


#################
###### COS ######
#################

#Miters=(64 128 256 512 1024)
Miters=(4096 16384 65536 262144)# 1048576)
let K_ex=16
let "N = $K_ex*$SM*BLOCK"

##### FUTURE #####
make clean
echo -e "${BLUE}compiling future...${NC}"
echo ""
make future

echo ***FUTURE_test***

#for((k=2; k<=32; k*=2));
#do
	
echo running with elements N = $N
for m in "${Miters[@]}"
do
	echo running with iterations M = $m
	for((j=0; j<9; j+=1));
	do
		echo $j	
		./bin/future.out $GPU $BLOCK $SM $m $N >> ./results/dev_cos_sp_inv.txt
	done
	echo 9
	sudo /usr/local/cuda-10.1/bin/nvprof --log-file ./profiling/dev_fut_sp_inv$N-$m.txt ./bin/future.out $GPU $BLOCK $SM $m $N >> ./results/dev_cos_sp_inv.txt
done
#done

##### FUTURE LOW #####
make clean
echo -e "${BLUE}compiling future low...${NC}"
echo ""
make futurelow

echo ***LOW PAR FUTURE_test***

#for((k=2; k<=32; k*=2));
#do
	#let "N = $k*$SM*$SM*BLOCK"
echo running with elements N = $N
for m in "${Miters[@]}"
do
	echo running with iterations M = $m
	for((j=0; j<9; j+=1));
	do
		echo $j	
		./bin/futurelow.out $GPU $BLOCK $SM $m $N >> ./results/dev_cos_sp_inv.txt
	done
	echo 9	
	sudo /usr/local/cuda-10.1/bin/nvprof --log-file ./profiling/dev_fut_sp_inv_low$N-$m.txt ./bin/futurelow.out $GPU $BLOCK $SM $m $N >> ./results/dev_cos_sp_inv.txt

done
#done



##### STREAM #####
make clean
echo -e "${BLUE}compiling stream...${NC}"
echo ""
make stream

echo ***STREAM_test***

#for((k=1; k<=16; k*=2));
#do
#	let "N = $k*$SM*$K_ex*$BLOCK"
echo running with elements N = $N
for m in "${Miters[@]}"
do
	echo running with iterations M = $m
	#echo iter number:
	for((j=0; j<9; j+=1));
	do
		echo $j
		./bin/stream.out $GPU $BLOCK $K_ex $m $N >> ./results/dev_cos_sp_inv.txt
	done
	echo 9
	sudo /usr/local/cuda-10.1/bin/nvprof --log-file ./profiling/dev_str_sp_inv$N-$m.txt ./bin/stream.out $GPU $BLOCK $K_ex $m $N >> ./results/dev_cos_sp_inv.txt

done
#done


##### STREAM LOW #####
make clean
echo -e "${BLUE}compiling stream low...${NC}"
echo ""
make streamlow 

echo ***LOW STREAM_test***

#for((k=1; k<=16; k*=2));
#do		
	#let "N = $k*$SM*$K_ex*$BLOCK"
echo running with elements N = $N
for m in "${Miters[@]}"
do
	echo running with iterations M = $m
	#echo iter number:
	for((j=0; j<9; j+=1));
	do
		echo $j
		./bin/streamlow.out $GPU $BLOCK $SK_ex $m $N >> ./results/dev_cos_sp_inv.txt
	done
	echo 9
	sudo /usr/local/cuda-10.1/bin/nvprof --log-file ./profiling/dev_str_sp_inv_low$N-$m.txt ./bin/streamlow.out $GPU $BLOCK $SK_ex $m $N >> ./results/dev_cos_sp_inv.txt

done
#done


let K_ex=1
#let "N = $K_ex*$SM*BLOCK"
let 
##### FUTURE STANDARD #####
make clean
echo -e "${BLUE}compiling future...${NC}"
echo ""
make future

echo ***FUTURE_STANDARD_test***

#for((k=2; k<=32; k*=2));
#do
	#let "N = $k*$SM*$SM*BLOCK"
echo running with elements N = $N
for m in "${Miters[@]}"
do
	echo running with iterations M = $m
	for((j=0; j<9; j+=1));
	do		
		echo $j	
		./bin/future.out $GPU $BLOCK $SM $m $N >> ./results/dev_cos_sp_inv.txt
	done
	echo 9	
	sudo /usr/local/cuda-10.1/bin/nvprof --log-file ./profiling/dev_fut_sp_inv_std$N-$m.txt ./bin/future.out $GPU $BLOCK $SM $m $N >> ./results/dev_cos_sp_inv.txt

done
#done


##### STREAM STANDARD #####
make clean
echo -e "${BLUE}compiling stream...${NC}"
echo ""
make stream

echo ***STREAM_STANDARD_test***

#for((k=1; k<=16; k*=2));
#do
	#let "N = $k*$SM*$K_ex*$BLOCK"
echo running with elements N = $N
for m in "${Miters[@]}"
do
	echo running with iterations M = $m
	#echo iter number:
	for((j=0; j<9; j+=1));
	do
		echo $j
		./bin/stream.out $GPU $BLOCK $K_ex $m $N >> ./results/dev_cos_sp_inv.txt
	done
	echo 9
	sudo /usr/local/cuda-10.1/bin/nvprof --log-file ./profiling/dev_str_sp_inv_std$N-$m.txt ./bin/stream.out $GPU $BLOCK $K_ex $m $N >> ./results/dev_cos_sp_inv.txt

done
#done


