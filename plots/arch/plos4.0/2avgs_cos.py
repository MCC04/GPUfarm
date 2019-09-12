#!/usr/bin/env python3
# coding=utf-8

#import glob
import os
import matplotlib.pyplot as plt
import numpy as np
import math
import csv


testNum=5

##########
###MAIN###
##########
def main():
	res_path = "../results/"+sys.argv[1]
	for file in os.listdir(res_path):
	    if file.endswith(".txt"):
		print(os.path.join(res_path, file))		
	
		
		if file[0:6]=="dev_sp":	

			f=os.path.join("../results/", file)
			lbls, evTimes, chronoTimes, chunkSizes, N, M, nStreams, blocks, grids = getDatas(f)
		
			csvPath="./output/"+file[0:-4]+"_avgs2.csv"
	
			print("Ev len: ",len(evTimes))
			print("Chrono len: ",len(chronoTimes))		
			print("Lbl len: ",len(lbls))						
		
			#evtmp=[evTimes[0]]
			#chtmp=[chronoTimes[0]]
			evtmp=[]
			chtmp=[]
			evAvgs=[]
			chAvgs=[]

			i=0
			for i in range(len(evTimes)):
				if i%testNum!=0 or i==0:
					evtmp.append(evTimes[i])
					chtmp.append(chronoTimes[i])		
				else:
					print("Ev TMP: ",evtmp)
					print("Ch TMP: ",chtmp)
					e, c = getChunkAvg(evtmp,chtmp)
					evAvgs.append(e)
					chAvgs.append(c)
					evtmp=[]
					chtmp=[]
					evtmp.append(evTimes[i])
					chtmp.append(chronoTimes[i])
					
			if len(evtmp)==8:
				e, c = getChunkAvg(evtmp,chtmp)
				evAvgs.append(e)
				chAvgs.append(c)
				
			
			lbls=lbls[0:len(lbls):testNum]
			chunkSizes=chunkSizes[0:len(chunkSizes):testNum]
			N=N[0:len(N):testNum]
			M=M[0:len(M):testNum]
			nStreams=nStreams[0:len(nStreams):testNum]
			blocks=blocks[0:len(blocks):testNum]
			grids=grids[0:len(grids):testNum]
						
						
			print("Event Averages: ",evAvgs)
			print("Chrono Averages: ",chAvgs)
			
			print("LEN Event Avg: ",len(evAvgs))
			print("LEN Chrono Avg: ",len(chAvgs))
			
			print("LBLs: ",lbls)
			
			lbl=lbls[0]
			with open(csvPath,  "wb") as fcsv:
				writer = csv.writer(fcsv) 
				writer.writerow([lbl])
				writer.writerow(['EVENTS','CHRONO','CHUNK','N SIZE','M ITERS','N STREAMS','BLOCK','GRID'])
				for i in range(len(evAvgs)):	
				
					if(lbl!=lbls[i]):
						lbl=lbls[i]
						writer.writerow([lbl])
						writer.writerow(['EVENTS','CHRONO','CHUNK','N SIZE','M ITERS','N STREAMS','BLOCK','GRID'])
					
					writer.writerow([evAvgs[i],chAvgs[i],chunkSizes[i],N[i],M[i],nStreams[i],blocks[i],grids[i]])
						
#########################
### GET DATA FROM TXT ###
#########################				
def getDatas(str):
	linesSeq = open(str, 'r')	
	charsSeq = [line.rstrip('\n') for line in linesSeq]
	
	tokens=[]
	lbls=[]
	evTimes=[]
	chronoTimes=[]
	chunkSizes=[]
	N=[]
	M=[]
	nStreams=[]
	blocks=[]
	grids=[]
	
	for line in charsSeq:
		tokens= line.split(',',11)
		lbls.append(tokens[0])
		evTimes.append(float(tokens[1]))
		chronoTimes.append(float(tokens[2]))	
		chunkSizes.append(int(tokens[3]))
		N.append(int(tokens[4]))
		M.append(int(tokens[5]))
		nStreams.append(int(tokens[6]))
		blocks.append(int(tokens[9]))
		grids.append(int(tokens[10]))		

	return lbls, evTimes, chronoTimes, chunkSizes, N, M, nStreams, blocks, grids
				
				
###############
### GET AVG ###
###############
def getChunkAvg(evT,chT):								
	evT.remove(min(evT))
	chT.remove(min(chT))
	evT.remove(max(evT))
	chT.remove(max(chT))


	ch = sum(chT[:])/len(chT)
	ev = sum(evT[:])/len(evT)
	
	return ev,ch
		

	
	
if __name__ == "__main__":
	main()


