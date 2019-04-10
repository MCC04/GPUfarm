# -*- Makefile -*-

#NEW_VERSION
CC:= nvcc
CFLAGS:= -std=c++14 -g -DMEASURES
ALLFLAGS:= $(CFLAGS) -Iinclude/ 
#FF_FLAGS:= -O3 -Ihome/maria/fastflow -pthread #-lstdc++fs 


BIN:=bin/
SRC:=src/
INCLUDE:=include/

FF_FLAGS:= -O3 -I$(INCLUDE)fastflow/ -pthread #-lstdc++fs 
#TARGETS:=future stream managed matmul blur




#all:
	#future stream managed matmul blur

####device####
#mat,imaging
.PHONY: matmul blurbox blurgauss future managed stream hcosseq hcospar hmmseq hmmpar clean



matmul: $(BIN)main_mat.o $(BIN)imageMatKernels.o $(BIN)cudaUtils.o
	$(CC) $(ALLFLAGS) $(BIN)main_mat.o $(BIN)imageMatKernels.o $(BIN)cudaUtils.o -o $(BIN)matmul.out

blurbox: $(BIN)main_imageMat.o $(BIN)imageMatKernels.o $(BIN)lodepng.o $(BIN)cudaUtils.o
	$(CC) $(ALLFLAGS) $(BIN)main_imageMat.o $(BIN)imageMatKernels.o $(BIN)lodepng.o $(BIN)cudaUtils.o -lstdc++fs -o $(BIN)blurbox.out

blurgauss: $(BIN)main_imageMat.o $(BIN)imageMatKernels.o $(BIN)lodepng.o $(BIN)cudaUtils.o
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
future: $(BIN)main_cos.o $(BIN)farmkernels.o $(BIN)cudaUtils.o
	$(CC) $(ALLFLAGS) $(BIN)main_cos.o $(BIN)farmkernels.o $(BIN)cudaUtils.o -o $(BIN)future.out

managed: $(BIN)main_cos.o $(BIN)farmkernels.o $(BIN)cudaUtils.o
	$(CC) $(ALLFLAGS) $(BIN)main_cos.o $(BIN)farmkernels.o $(BIN)cudaUtils.o -o $(BIN)managed.out

stream: $(BIN)main_cos.o $(BIN)farmkernels.o $(BIN)cudaUtils.o
	$(CC) $(ALLFLAGS) $(BIN)main_cos.o $(BIN)farmkernels.o $(BIN)cudaUtils.o -o $(BIN)stream.out

empty: $(BIN)main_cos.o $(BIN)farmkernels.o $(BIN)cudaUtils.o
	$(CC) $(ALLFLAGS) $(BIN)main_cos.o $(BIN)farmkernels.o $(BIN)cudaUtils.o -o $(BIN)empty.out

$(BIN)main_cos.o: $(SRC)main_cos.cpp $(INCLUDE)cosFutStr.h $(INCLUDE)cudaUtils.h
	$(CC) $(ALLFLAGS) -c $(SRC)main_cos.cpp -D$(shell echo $(MAKECMDGOALS) | tr a-z A-Z) -o $(BIN)main_cos.o

$(BIN)farmkernels.o:  $(SRC)farmkernels.cu $(INCLUDE)cosFutStr.h $(INCLUDE)cudaUtils.h
	$(CC) $(ALLFLAGS) -c $(SRC)farmkernels.cu -o $(BIN)farmkernels.o

$(BIN)cudaUtils.o: $(SRC)cudaUtils.cpp  $(INCLUDE)cudaUtils.h
	$(CC) $(ALLFLAGS) -c $(SRC)cudaUtils.cpp -o $(BIN)cudaUtils.o

####host:####
hcosseq: $(BIN)hostfarm.o
	g++ $(CFLAGS) $(BIN)hostfarm.o $(FF_FLAGS) -o $(BIN)hcosseq.out

hcospar: $(BIN)hostfarm.o
	g++ $(CFLAGS) $(BIN)hostfarm.o $(FF_FLAGS) -o $(BIN)hcospar.out

hmmseq: $(BIN)hostfarm.o #$(BIN)ff_streamMM.o
	g++ $(CFLAGS) $(BIN)hostfarm.o $(FF_FLAGS) -o $(BIN)hmmseq.out

hmmpar: $(BIN)hostfarm.o #$(BIN)ff_streamMM.o
	g++ $(CFLAGS) $(BIN)hostfarm.o $(FF_FLAGS) -o $(BIN)hmmpar.out

$(BIN)hostfarm.o: $(SRC)hostfarm.cpp
	g++ $(CFLAGS) -c $(SRC)hostfarm.cpp $(FF_FLAGS) -D$(shell echo $(MAKECMDGOALS) | tr a-z A-Z) -o $(BIN)hostfarm.o

#$(BIN)ff_streamMM.o: $(SRC)/ff_streamMM.cpp
#	g++ $(CFLAGS) -c $(SRC)/ff_streamMM.cpp $(FF_FLAGS) -o $(BIN)ff_streamMM.o


#hostmatmul: hostmatmul.o
#	g++ $(CFLAGS) hostmatmul.o $(FF_FLAGS) -o hostmatmul

#hostmatmul.o:
#	g++ $(CFLAGS) -c hostmatmul.cpp $(FF_FLAGS)

####clean####
clean:
	rm -f $(BIN)*.o 
	rm -f $(BIN)*.out
	#rm -f $(BIN)$(MAKECMDGOALS)



