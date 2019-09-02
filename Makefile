# -*- Makefile -*-

CC:= nvcc
CFLAGS:= -std=c++14 -g -G -DMEASURES
ALLFLAGS:= $(CFLAGS) -Iinclude/ 
#FF_FLAGS:= -O3 -I/home/maria/fastflow/ -pthread #-lstdc++fs 
LOWPAR:= $(ALLFLAGS) -DLOWPAR


BIN:=bin/
BINCOS:=bin/cos/
BINMAT:=bin/mat/
SRC:=src/
INCLUDE:=include/

FF_FLAGS:= -O3 -I$(INCLUDE)fastflow/ -pthread #-lstdc++fs 

.PHONY: matmul blurbox future stream hcosseq hcospar hmmseq hmmpar cleanall clean cleancos cleanmat cleandplow


################
#### DEVICE ####
################
#mat,imaging
matmul: $(BINMAT)matmul.out
blurbox: $(BINMAT)blurbox.out

$(BINMAT)matmul.out: $(BINMAT)main_mat.o $(BINMAT)imageMatKernels.o $(BIN)cudaUtils.o
	$(CC) $(ALLFLAGS) $(BINMAT)imageMatKernels.o $(BINMAT)main_mat.o $(BIN)cudaUtils.o -o $(BINMAT)matmul.out

$(BINMAT)blurbox.out: $(BINMAT)main_imageMat.o $(BINMAT)imageMatKernels.o $(BINMAT)lodepng.o $(BIN)cudaUtils.o
	$(CC) $(ALLFLAGS) $(BINMAT)main_imageMat.o $(BINMAT)imageMatKernels.o $(BINMAT)lodepng.o $(BIN)cudaUtils.o -lstdc++fs -o $(BINMAT)blurbox.out

$(BINMAT)main_imageMat.o: $(SRC)main_imageMat.cpp $(INCLUDE)lodepng.h $(INCLUDE)cudaUtils.h $(INCLUDE)imageMatrix.h
	$(CC) $(ALLFLAGS) -c $(SRC)main_imageMat.cpp -D$(shell echo $(MAKECMDGOALS) | tr a-z A-Z) -o $(BINMAT)main_imageMat.o

$(BINMAT)imageMatKernels.o:  $(SRC)imageMatKernels.cu $(INCLUDE)cudaUtils.h $(INCLUDE)imageMatrix.h 
	$(CC) $(ALLFLAGS) -c $(SRC)imageMatKernels.cu -D$(shell echo $(MAKECMDGOALS) | tr a-z A-Z) -o $(BINMAT)imageMatKernels.o

$(BINMAT)main_mat.o: $(SRC)main_imageMat.cpp $(INCLUDE)cudaUtils.h $(INCLUDE)imageMatrix.h 
	$(CC) $(ALLFLAGS) -c $(SRC)main_imageMat.cpp -D$(shell echo $(MAKECMDGOALS) | tr a-z A-Z) -o $(BINMAT)main_mat.o
	
$(BINMAT)lodepng.o: $(SRC)lodepng.cpp  $(INCLUDE)lodepng.h
	$(CC) $(ALLFLAGS) -c $(SRC)lodepng.cpp -o $(BINMAT)lodepng.o
	

#cos future, stream
future: $(BINCOS)future.out
#managed: $(BINCOS)managed.out
stream: $(BINCOS)stream.out
datapar: $(BIN)datapar.out

autosched: $(BINCOS)autosched.out

$(BINCOS)autosched.out: $(BIN)cudaUtils.o $(BINCOS)farmkernels.o $(BINCOS)autoScheduler.o 
	$(CC) $(ALLFLAGS) $(BINCOS)autoScheduler.o $(BINCOS)farmkernels.o $(BIN)cudaUtils.o -o $(BINCOS)autosched.out

$(BINCOS)future.out: $(BIN)cudaUtils.o $(BINCOS)farmkernels.o $(BINCOS)main_cos.o  
	$(CC) $(ALLFLAGS) $(BINCOS)main_cos.o $(BINCOS)farmkernels.o $(BIN)cudaUtils.o -o $(BINCOS)future.out

 #$(BINCOS)managed.out: $(BIN)cudaUtils.o $(BINCOS)farmkernels.o $(BINCOS)main_cos.o  
#	$(CC) $(ALLFLAGS) $(BINCOS)main_cos.o $(BINCOS)farmkernels.o $(BIN)cudaUtils.o -o $(BINCOS)managed.out

$(BINCOS)stream.out: $(BIN)cudaUtils.o $(BINCOS)farmkernels.o $(BINCOS)main_cos.o  
	$(CC) $(ALLFLAGS) $(BINCOS)main_cos.o $(BINCOS)farmkernels.o $(BIN)cudaUtils.o -o $(BINCOS)stream.out


#data par only#
$(BIN)datapar.out: $(BIN)cudaUtils.o $(BIN)farmkernels_dp.o $(BIN)main_cos_dp.o  
	$(CC) $(ALLFLAGS) $(BIN)main_cos_dp.o $(BIN)farmkernels_dp.o $(BIN)cudaUtils.o -o $(BIN)datapar.out

$(BIN)main_cos_dp.o: $(SRC)main_cos.cpp $(INCLUDE)cosFutStr.h $(INCLUDE)cudaUtils.h
	$(CC) $(ALLFLAGS) -c $(SRC)main_cos.cpp -D$(shell echo $(MAKECMDGOALS) | tr a-z A-Z) -o $(BIN)main_cos_dp.o

$(BIN)farmkernels_dp.o:  $(SRC)farmkernels.cu $(INCLUDE)cosFutStr.h $(INCLUDE)cudaUtils.h
	$(CC) $(ALLFLAGS) -c $(SRC)farmkernels.cu -D$(shell echo $(MAKECMDGOALS) | tr a-z A-Z) -o $(BIN)farmkernels_dp.o
###



$(BINCOS)autoScheduler.o: $(SRC)autoScheduler.cpp $(INCLUDE)cosFutStr.h $(INCLUDE)cudaUtils.h
	$(CC) $(ALLFLAGS) -c $(SRC)autoScheduler.cpp -D$(shell echo $(MAKECMDGOALS) | tr a-z A-Z) -o $(BINCOS)autoScheduler.o

$(BINCOS)main_cos.o: $(SRC)main_cos.cpp $(INCLUDE)cosFutStr.h $(INCLUDE)cudaUtils.h
	$(CC) $(ALLFLAGS) -c $(SRC)main_cos.cpp -D$(shell echo $(MAKECMDGOALS) | tr a-z A-Z) -o $(BINCOS)main_cos.o

$(BINCOS)farmkernels.o:  $(SRC)farmkernels.cu $(INCLUDE)cosFutStr.h $(INCLUDE)cudaUtils.h
	$(CC) $(ALLFLAGS) -c $(SRC)farmkernels.cu -D$(shell echo $(MAKECMDGOALS) | tr a-z A-Z) -o $(BINCOS)farmkernels.o

$(BIN)cudaUtils.o: $(SRC)cudaUtils.cpp  $(INCLUDE)cudaUtils.h
	$(CC) $(ALLFLAGS) -c $(SRC)cudaUtils.cpp -o $(BIN)cudaUtils.o

####DEV LOW PARALLELISM####
#mat,imaging
matmullow: $(BIN)matmullow.out
blurboxlow: $(BIN)blurboxlow.out

$(BIN)matmullow.out: $(BIN)main_mat_low.o $(BIN)imageMatKernels_low.o $(BIN)cudaUtils.o
	$(CC) $(LOWPAR) $(BIN)main_mat_low.o $(BIN)imageMatKernels_low.o $(BIN)cudaUtils.o -o $(BIN)matmullow.out

$(BIN)blurboxlow.out: $(BIN)main_imageMat_low.o $(BIN)imageMatKernels_low.o $(BINMAT)lodepng.o $(BIN)cudaUtils.o
	$(CC) $(LOWPAR) $(BIN)main_imageMat_low.o $(BIN)imageMatKernels_low.o $(BINMAT)lodepng.o $(BIN)cudaUtils.o -lstdc++fs -o $(BIN)blurboxlow.out

$(BIN)main_imageMat_low.o: $(SRC)main_imageMat.cpp $(INCLUDE)imageMatrix.h $(INCLUDE)lodepng.h $(INCLUDE)cudaUtils.h
	$(CC) $(LOWPAR) -c $(SRC)main_imageMat.cpp -D$(shell echo $(MAKECMDGOALS) | tr a-z A-Z | rev | cut -c 4- | rev) -o $(BIN)main_imageMat_low.o

$(BIN)imageMatKernels_low.o:  $(SRC)imageMatKernels.cu $(INCLUDE)imageMatrix.h $(INCLUDE)cudaUtils.h
	$(CC) $(LOWPAR) -c $(SRC)imageMatKernels.cu -D$(shell echo $(MAKECMDGOALS) | tr a-z A-Z | rev | cut -c 4- | rev) -o $(BIN)imageMatKernels_low.o

$(BIN)main_mat_low.o: $(SRC)main_imageMat.cpp $(INCLUDE)imageMatrix.h $(INCLUDE)cudaUtils.h
	$(CC) $(LOWPAR) -c $(SRC)main_imageMat.cpp -D$(shell echo $(MAKECMDGOALS) | tr a-z A-Z | rev | cut -c 4- | rev) -o $(BIN)main_mat_low.o
	

#cos future, stream
futurelow: $(BIN)futurelow.out
#managedlow: $(BIN)managedlow.out
streamlow: $(BIN)streamlow.out
dataparlow: $(BIN)dataparlow.out


$(BIN)futurelow.out: $(BIN)main_cos_low.o $(BIN)farmkernels_low.o $(BIN)cudaUtils.o
	$(CC) $(LOWPAR) $(BIN)main_cos_low.o $(BIN)farmkernels_low.o $(BIN)cudaUtils.o -o $(BIN)futurelow.out

#$(BIN)managedlow.out: $(BIN)main_cos_low.o $(BIN)farmkernels_low.o $(BIN)cudaUtils.o
#	$(CC) $(LOWPAR) $(BIN)main_cos_low.o $(BIN)farmkernels_low.o $(BIN)cudaUtils.o -o $(BIN)managedlow.out

$(BIN)streamlow.out: $(BIN)main_cos_low.o $(BIN)farmkernels_low.o $(BIN)cudaUtils.o
	$(CC) $(LOWPAR) $(BIN)main_cos_low.o $(BIN)farmkernels_low.o $(BIN)cudaUtils.o -o $(BIN)streamlow.out

$(BIN)dataparlow.out: $(BIN)main_cos_low.o $(BIN)farmkernels_low.o $(BIN)cudaUtils.o
	$(CC) $(LOWPAR) $(BIN)main_cos_low.o $(BIN)farmkernels_low.o $(BIN)cudaUtils.o -o $(BIN)dataparlow.out

$(BIN)main_cos_low.o: $(SRC)main_cos.cpp $(INCLUDE)cosFutStr.h $(INCLUDE)cudaUtils.h
	$(CC) $(LOWPAR) -c $(SRC)main_cos.cpp -D$(shell echo $(MAKECMDGOALS) | tr a-z A-Z | rev | cut -c 4- | rev) -o $(BIN)main_cos_low.o

$(BIN)farmkernels_low.o:  $(SRC)farmkernels.cu $(INCLUDE)cosFutStr.h $(INCLUDE)cudaUtils.h
	$(CC) $(LOWPAR) -c $(SRC)farmkernels.cu -D$(shell echo $(MAKECMDGOALS) | tr a-z A-Z | rev | cut -c 4- | rev) -o $(BIN)farmkernels_low.o





##############
#### HOST ####
##############
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



##################
#### CLEANING ####
##################
clean:
	rm -f $(BIN)*.o 
	rm -f $(BIN)*.out

cleancos:
	rm -f $(BINCOS)*.o 
	rm -f $(BINCOS)*.out

cleandplow:
	rm -f $(BIN)*low.o 
	rm -f $(BIN)*low.out
	rm -f $(BIN)datapar*

cleanmat:
	rm -f $(BINMAT)*.o 
	rm -f $(BINMAT)*.out

cleanall:
	rm -f $(BIN)*.o 
	rm -f $(BIN)*.out

	rm -f $(BINCOS)*.o 
	rm -f $(BINCOS)*.out

	rm -f $(BINMAT)*.o 
	rm -f $(BINMAT)*.out
