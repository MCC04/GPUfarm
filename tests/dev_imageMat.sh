#!/bin/bash

rm -f ./results/dev_imageMat.txt
touch ./results/dev_imageMat.txt

rm -f ./profiling/dev_imageMat.txt
#touch ./profiling/dev_imageMat.txt

#ARGS="device nExec kerIters elemNum" >> dev_imageMat.txt
#standard

BLUE='\033[1;34m'
NC='\033[0m'

let GPU=1

############
make clean
echo -e "${BLUE}compiling matmul...${NC}"
echo ""
make matmul
let "BLOCK=32"
echo ***MATMUL_test***

for((i=0; i<=15; i+=1));
do
	echo iter = $i
	for((l=1; l<=5; l+=1));
	do		
		let "M = $l*$BLOCK*8"
		let "K = $M+1"
		let "N = $M+2"
		echo running with M = $M , K = $K , N = $N 

		for((j=1; j<=5; j+=1));
		do
			let "Nmat = $j*56"
			echo number of matrices = $Nmat
			
			nvprof --log-file ./profiling/dev_imageMat$l-$j.txt ./bin/matmul.out $GPU $BLOCK 4 $M $K $N $Nmat >> ./results/dev_imageMat.txt
		done
	done
done
##########
make clean
echo -e "${BLUE}compiling blurbox...${NC}"
echo ""
make blurbox

echo ***BLURBOX_test***

let BLOCK=512
echo "block size set to $BLOCK"
for((i=0; i<=15; i+=1));
do
	#for((k=2; k<=32; k*=2));
	#do
		echo running with i = $i
		#let "N = $k*56*32"
	
		#for((i=10; i<=1250; i*=5));
		#do
			#echo iterations M = $i
                        
                        
                        
                        
                        
                        #nvprof --log-file ./profiling/dev_imageMat_$BLOCK-$i.txt ./bin/blurbox.out $GPU $BLOCK 4  >> ./results/dev_imageMat_$BLOCK.txt
                        nvprof --log-file ./profiling/dev_imageMat_$BLOCK-$i.txt ./bin/blurbox.out $GPU $BLOCK 4  >> ./results/dev_imageMat.txt
                        
                        
                        
                        
done

let BLOCK=1024
echo "block size set to $BLOCK"
for((i=0; i<=15; i+=1));
do                
	echo running with i = $i
        #nvprof --log-file ./profiling/dev_imageMat_$BLOCK-$i.txt ./bin/blurbox.out $GPU $BLOCK 4  >> ./results/dev_imageMat_$BLOCK.txt
	nvprof --log-file ./profiling/dev_imageMat_$BLOCK-$i.txt ./bin/blurbox.out $GPU $BLOCK 4  >> ./results/dev_imageMat.txt
			
		
		
		
		
		
		
		
		#done
		#nvprof --log-file ./profiling/dev_imageMat$k-2500.txt ./blurbox.out $GPU $BLOCK   >> ./results/dev_imageMat.txt
	#done
done

##########
#amek clean
#echo "compiling blurgauss executable..."
#echo ""
#make blurgauss
#echo ***BLURGAUSS_test***
#for((j=0; j<=15; j+=1));
#do
#	for((k=2; k<=32; k*=2));
#	do
#		echo running with k = $k
#		let "N = $k*56*32"
#	
#		for((i=10; i<=1250; i*=5));
#		do
#			echo iterations M = $i
#                        nvprof --log-file ./profiling/dev_imageMat$k-$i.txt ./blurgauss.out $GPU $BLOCK >> ./results/dev_imageMat.txt
#		done
#		nvprof --log-file ./profiling/dev_imageMat$k-2500.txt ./blurgauss.out $GPU $BLOCK >> ./results/dev_imageMat.txt
#	done
#done





