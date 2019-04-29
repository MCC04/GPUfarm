# -*- Makefile -*-

CC:= nvcc
CFLAGS:= -std=c++11 -g 
ALLFLAGS:= $(CFLAGS) -Iinclude/ 
FF_FLAGS:= -O3 -Ihome/maria/fastflow -pthread #-lstdc++fs 

BIN:=bin/
SRC:=src/
INCLUDE:=include/

#TARGETS:=future stream managed matmul blur

all:
	future stream managed matmul blur

####device####
future: $(BIN)main_device.o $(BIN)farmkernels.o
	$(CC) $(ALLFLAGS) $(BIN)main_device.o $(BIN)farmkernels.o -o $(BIN)future

managed: $(BIN)main_device.o $(BIN)farmkernels.o
	$(CC) $(ALLFLAGS) $(BIN)main_device.o $(BIN)farmkernels.o -o $(BIN)managed

stream: $(BIN)main_device.o $(BIN)farmkernels.o
	$(CC) $(ALLFLAGS) $(BIN)main_device.o $(BIN)farmkernels.o -o $(BIN)stream

matmul: $(BIN)main_device.o $(BIN)farmkernels.o
	$(CC) $(ALLFLAGS) $(BIN)main_device.o $(BIN)farmkernels.o -o $(BIN)matmul

blur: $(BIN)main_device.o $(BIN)farmkernels.o $(BIN)lodepng.o 
	$(CC) $(ALLFLAGS) $(BIN)main_device.o $(BIN)farmkernels.o $(BIN)lodepng.o  -lstdc++fs -o $(BIN)blur


$(BIN)main_device.o: $(SRC)main_device.cpp $(INCLUDE)gpufarm.h  $(INCLUDE)lodepng.h
	$(CC) $(ALLFLAGS) -c $(SRC)main_device.cpp -D$(shell echo $(MAKECMDGOALS) | tr a-z A-Z) -o $(BIN)main_device.o

$(BIN)farmkernels.o:  $(SRC)farmkernels.cu $(INCLUDE)gpufarm.h 
	$(CC) $(ALLFLAGS) -c $(SRC)farmkernels.cu -o $(BIN)farmkernels.o

$(BIN)lodepng.o: $(SRC)lodepng.cpp  $(INCLUDE)lodepng.h
	$(CC) $(ALLFLAGS) -c $(SRC)lodepng.cpp -o $(BIN)lodepng.o

####host:####
hostcos: hostfarm.o
	g++ $(CFLAGS) hostfarm.o $(FF_FLAGS) -o hostcos

hostfarm.o:
	g++ $(CFLAGS) -c $(SRC)/hostfarm.cpp $(FF_FLAGS)


hostmatmul: hostmatmul.o
	g++ $(CFLAGS) hostmatmul.o $(FF_FLAGS) -o hostmatmul

hostmatmul.o:
	g++ $(CFLAGS) -c hostmatmul.cpp $(FF_FLAGS)

####clean####
.PHONY: clean
clean:
	rm -f $(BIN)*.o 
	rm -f $(BIN)*.out
	rm -f $(BIN)$(MAKECMDGOALS)



