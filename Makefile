# -*- Makefile -*-

CC:= nvcc
CFLAGS:= -std=c++14 -g -DMEASURES
ALLFLAGS:= $(CFLAGS) -Iinclude/ 
#FF_FLAGS:= -O3 -I/home/maria/fastflow/ -pthread #-lstdc++fs 
LOWPAR:= $(ALLFLAGS) -DLOWPAR


BIN:=bin/
SRC:=src/
INCLUDE:=include/

FF_FLAGS:= -O3 -I$(INCLUDE)fastflow/ -pthread #-lstdc++fs 
#FF_FLAGS:=  -I$(INCLUDE)fastflow/ -pthread #-lstdc++fs 


.PHONY: matmul blurbox blurgauss future managed stream hcosseq hcospar hmmseq hmmpar clean

####DEVICE####
#mat,imaging
matmul: $(BIN)matmul.out
smallmatmul: $(BIN)smallmatmul.out
blurbox: $(BIN)blurbox.out
blurgauss: $(BIN)blurgauss.out

$(BIN)matmul.out: $(BIN)main_mat.o $(BIN)imageMatKernels.o $(BIN)cudaUtils.o
	$(CC) $(ALLFLAGS) $(BIN)main_mat.o $(BIN)imageMatKernels.o $(BIN)cudaUtils.o -o $(BIN)matmul.out

$(BIN)smallmatmul.out: $(BIN)main_mat.o $(BIN)imageMatKernels.o $(BIN)cudaUtils.o
	$(CC) $(ALLFLAGS) $(BIN)main_mat.o $(BIN)imageMatKernels.o $(BIN)cudaUtils.o -o $(BIN)smallmatmul.out

$(BIN)blurbox.out: $(BIN)main_imageMat.o $(BIN)imageMatKernels.o $(BIN)lodepng.o $(BIN)cudaUtils.o
	$(CC) $(ALLFLAGS) $(BIN)main_imageMat.o $(BIN)imageMatKernels.o $(BIN)lodepng.o $(BIN)cudaUtils.o -lstdc++fs -o $(BIN)blurbox.out

$(BIN)blurgauss.out: $(BIN)main_imageMat.o $(BIN)imageMatKernels.o $(BIN)lodepng.o $(BIN)cudaUtils.o
	$(CC) $(ALLFLAGS) $(BIN)main_imageMat.o $(BIN)imageMatKernels.o $(BIN)lodepng.o $(BIN)cudaUtils.o -lstdc++fs -o $(BIN)blurgauss.out

$(BIN)main_imageMat.o: $(SRC)main_imageMat.cpp $(INCLUDE)imageMatrix.h $(INCLUDE)lodepng.h $(INCLUDE)cudaUtils.h
	$(CC) $(ALLFLAGS) -c $(SRC)main_imageMat.cpp -D$(shell echo $(MAKECMDGOALS) | tr a-z A-Z) -o $(BIN)main_imageMat.o

$(BIN)imageMatKernels.o:  $(SRC)imageMatKernels.cu $(INCLUDE)imageMatrix.h $(INCLUDE)cudaUtils.h
	$(CC) $(ALLFLAGS) -c $(SRC)imageMatKernels.cu -o $(BIN)imageMatKernels.o

$(BIN)main_mat.o: $(SRC)main_imageMat.cpp $(INCLUDE)imageMatrix.h $(INCLUDE)cudaUtils.h
	$(CC) $(ALLFLAGS) -c $(SRC)main_imageMat.cpp -D$(shell echo $(MAKECMDGOALS) | tr a-z A-Z) -o $(BIN)main_mat.o
	
$(BIN)lodepng.o: $(SRC)lodepng.cpp  $(INCLUDE)lodepng.h
	$(CC) $(ALLFLAGS) -c $(SRC)lodepng.cpp -o $(BIN)lodepng.o
	

#cos future, stream, managed
future: $(BIN)future.out
managed: $(BIN)managed.out
stream: $(BIN)stream.out
empty: $(BIN)empty.out


$(BIN)future.out: $(BIN)main_cos.o $(BIN)farmkernels.o $(BIN)cudaUtils.o
	$(CC) $(ALLFLAGS) $(BIN)main_cos.o $(BIN)farmkernels.o $(BIN)cudaUtils.o -o $(BIN)future.out

$(BIN)managed.out: $(BIN)main_cos.o $(BIN)farmkernels.o $(BIN)cudaUtils.o
	$(CC) $(ALLFLAGS) $(BIN)main_cos.o $(BIN)farmkernels.o $(BIN)cudaUtils.o -o $(BIN)managed.out

$(BIN)stream.out: $(BIN)main_cos.o $(BIN)farmkernels.o $(BIN)cudaUtils.o
	$(CC) $(ALLFLAGS) $(BIN)main_cos.o $(BIN)farmkernels.o $(BIN)cudaUtils.o -o $(BIN)stream.out

$(BIN)empty.out: $(BIN)main_cos.o $(BIN)farmkernels.o $(BIN)cudaUtils.o
	$(CC) $(ALLFLAGS) $(BIN)main_cos.o $(BIN)farmkernels.o $(BIN)cudaUtils.o -o $(BIN)empty.out


$(BIN)main_cos.o: $(SRC)main_cos.cpp $(INCLUDE)cosFutStr.h $(INCLUDE)cudaUtils.h
	$(CC) $(ALLFLAGS) -c $(SRC)main_cos.cpp -D$(shell echo $(MAKECMDGOALS) | tr a-z A-Z) -o $(BIN)main_cos.o

$(BIN)farmkernels.o:  $(SRC)farmkernels.cu $(INCLUDE)cosFutStr.h $(INCLUDE)cudaUtils.h
	$(CC) $(ALLFLAGS) -c $(SRC)farmkernels.cu -o $(BIN)farmkernels.o

$(BIN)cudaUtils.o: $(SRC)cudaUtils.cpp  $(INCLUDE)cudaUtils.h
	$(CC) $(ALLFLAGS) -c $(SRC)cudaUtils.cpp -o $(BIN)cudaUtils.o

####DEV LOW PARALLELISM####
#mat,imaging
matmullow: $(BIN)matmullow.out
smallmatmullow: $(BIN)smallmatmullow.out
blurboxlow: $(BIN)blurboxlow.out


$(BIN)matmullow.out: $(BIN)main_mat_low.o $(BIN)imageMatKernels_low.o $(BIN)cudaUtils.o
	$(CC) $(LOWPAR) $(BIN)main_mat_low.o $(BIN)imageMatKernels_low.o $(BIN)cudaUtils.o -o $(BIN)matmullow.out

$(BIN)smallmatmullow.out: $(BIN)main_mat_low.o $(BIN)imageMatKernels_low.o $(BIN)cudaUtils.o
	$(CC) $(LOWPAR) $(BIN)main_mat_low.o $(BIN)imageMatKernels_low.o $(BIN)cudaUtils.o -o $(BIN)smallmatmullow.out

$(BIN)blurboxlow.out: $(BIN)main_imageMat_low.o $(BIN)imageMatKernels_low.o $(BIN)lodepng.o $(BIN)cudaUtils.o
	$(CC) $(LOWPAR) $(BIN)main_imageMat_low.o $(BIN)imageMatKernels_low.o $(BIN)lodepng.o $(BIN)cudaUtils.o -lstdc++fs -o $(BIN)blurboxlow.out

#blurgauss: $(BIN)main_imageMat_low.o $(BIN)imageMatKernels_low.o $(BIN)lodepng.o $(BIN)cudaUtils.o
	#$(CC) $(LOWPAR) $(BIN)main_imageMat_low.o $(BIN)imageMatKernels_low.o $(BIN)lodepng.o $(BIN)cudaUtils.o -lstdc++fs -o $(BIN)blurgauss.out

$(BIN)main_imageMat_low.o: $(SRC)main_imageMat.cpp $(INCLUDE)imageMatrix.h $(INCLUDE)lodepng.h $(INCLUDE)cudaUtils.h
	$(CC) $(LOWPAR) -c $(SRC)main_imageMat.cpp -D$(shell echo $(MAKECMDGOALS) | tr a-z A-Z | rev | cut -c 4- | rev) -o $(BIN)main_imageMat_low.o

$(BIN)imageMatKernels_low.o:  $(SRC)imageMatKernels.cu $(INCLUDE)imageMatrix.h $(INCLUDE)cudaUtils.h
	$(CC) $(LOWPAR) -c $(SRC)imageMatKernels.cu -o $(BIN)imageMatKernels_low.o

$(BIN)main_mat_low.o: $(SRC)main_imageMat.cpp $(INCLUDE)imageMatrix.h $(INCLUDE)cudaUtils.h
	$(CC) $(LOWPAR) -c $(SRC)main_imageMat.cpp -D$(shell echo $(MAKECMDGOALS) | tr a-z A-Z | rev | cut -c 4- | rev) -o $(BIN)main_mat_low.o
	

#cos future, stream, managed
futurelow: $(BIN)futurelow.out
managedlow: $(BIN)managedlow.out
streamlow: $(BIN)streamlow.out


$(BIN)futurelow.out: $(BIN)main_cos_low.o $(BIN)farmkernels_low.o $(BIN)cudaUtils.o
	$(CC) $(LOWPAR) $(BIN)main_cos_low.o $(BIN)farmkernels_low.o $(BIN)cudaUtils.o -o $(BIN)futurelow.out

$(BIN)managedlow.out: $(BIN)main_cos_low.o $(BIN)farmkernels_low.o $(BIN)cudaUtils.o
	$(CC) $(LOWPAR) $(BIN)main_cos_low.o $(BIN)farmkernels_low.o $(BIN)cudaUtils.o -o $(BIN)managedlow.out

$(BIN)streamlow.out: $(BIN)main_cos_low.o $(BIN)farmkernels_low.o $(BIN)cudaUtils.o
	$(CC) $(LOWPAR) $(BIN)main_cos_low.o $(BIN)farmkernels_low.o $(BIN)cudaUtils.o -o $(BIN)streamlow.out

$(BIN)main_cos_low.o: $(SRC)main_cos.cpp $(INCLUDE)cosFutStr.h $(INCLUDE)cudaUtils.h
	$(CC) $(LOWPAR) -c $(SRC)main_cos.cpp -D$(shell echo $(MAKECMDGOALS) | tr a-z A-Z | rev | cut -c 4- | rev) -o $(BIN)main_cos_low.o

$(BIN)farmkernels_low.o:  $(SRC)farmkernels.cu $(INCLUDE)cosFutStr.h $(INCLUDE)cudaUtils.h
	$(CC) $(LOWPAR) -c $(SRC)farmkernels.cu -o $(BIN)farmkernels_low.o


####HOST####
hcosseq: $(BIN)hcosseq.out
hcospar: $(BIN)hcospar.out
hmmseq: $(BIN)hmmseq.out
hmmpar: $(BIN)hmmpar.out


$(BIN)hcosseq.out: $(BIN)hostfarm.o
	g++ $(CFLAGS) $(BIN)hostfarm.o $(FF_FLAGS) -o $(BIN)hcosseq.out

$(BIN)hcospar.out: $(BIN)hostfarm.o
	g++ $(CFLAGS) $(BIN)hostfarm.o $(FF_FLAGS) -o $(BIN)hcospar.out

$(BIN)hmmseq.out: $(BIN)hostfarm.o 
	g++ $(CFLAGS) $(BIN)hostfarm.o $(FF_FLAGS) -o $(BIN)hmmseq.out

$(BIN)hmmpar.out: $(BIN)hostfarm.o 
	g++ $(CFLAGS) $(BIN)hostfarm.o $(FF_FLAGS) -o $(BIN)hmmpar.out

$(BIN)hostfarm.o: $(SRC)hostfarm.cpp
	g++ $(CFLAGS) -c $(SRC)hostfarm.cpp $(FF_FLAGS) -D$(shell echo $(MAKECMDGOALS) | tr a-z A-Z) -o $(BIN)hostfarm.o

####clean####
clean:
	rm -f $(BIN)*.o 
	rm -f $(BIN)*.out
