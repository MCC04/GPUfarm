#!/usr/bin/env python3
# coding=utf-8

#import glob
import os
import matplotlib.pyplot as plt
import numpy as np
import math
import csv
import sys


testNum=5

##########
###MAIN###
##########

#import pdb; pdb.set_trace()
def main():
	
	res_path = "../results/"+sys.argv[1]+"/"
	for file in os.listdir(res_path):
	    if file.endswith(".txt"):
		print(os.path.join(res_path, file))		
	
		
		if file[0:4]=="dev_":	
			
			##########################
			# get all measures in .txt
			##########################
			f=os.path.join(res_path, file)
			resType=file[4:7]
			
			#common
			lbls=[]
			evTimes=[]
			chronoTimes=[]
			nStreams=[]
			blocks=[]
			grids=[]
			#cos only
			chunkSizes=[]
			N=[]
			M=[]
			#mat only
			matSize=[]
			numMat=[]
			#blur only
			imgNum=[]
			sizeImg=[]
			
			if resType=="cos":
				lbls,evTimes,chronoTimes,chunkSizes,N,M,nStreams,blocks,grids = getCosDatas(f)
			elif resType=="mat":
				lbls,evTimes,chronoTimes,matSize,numMat,nStreams,blocks,grids = getMatDatas(f)
			elif resType=="blu":
				lbls,evTimes,chronoTimes,sizeImg,imgNum,nStreams,blocks,grids = getBlurDatas(f)
				
			csvPath="./output/"+sys.argv[1]+"/"+resType+"_avgs.csv"
	
			print("Ev len: ",len(evTimes))
			print("Chrono len: ",len(chronoTimes))		
			print("Lbl len: ",len(lbls))						
		
			#######################
			# get measures averages
			#######################
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
					
			if len(evtmp)==testNum:
				e, c = getChunkAvg(evtmp,chtmp)
				evAvgs.append(e)
				chAvgs.append(c)
				
			
			#####################
			# shrink input arrays
			#####################
			if resType=="cos":
				chunkSizes=chunkSizes[0:len(chunkSizes):testNum]
				N=N[0:len(N):testNum]
				M=M[0:len(M):testNum]
				#nStreams=nStreams[0:len(nStreams):testNum]
				
			elif resType=="mat":
				matSize=matSize[0:len(matSize):testNum]
				numMat=numMat[0:len(numMat):testNum]
				
			elif resType=="blu":
				imgNum=imgNum[0:len(imgNum):testNum]
				sizeImg=sizeImg[0:len(sizeImg):testNum]

			lbls=lbls[0:len(lbls):testNum]
			nStreams=nStreams[0:len(nStreams):testNum]
			blocks=blocks[0:len(blocks):testNum]
			grids=grids[0:len(grids):testNum]
						
						
			print("Event Averages: ",evAvgs)
			print("Chrono Averages: ",chAvgs)
			
			print("LEN Event Avg: ",len(evAvgs))
			print("LEN Chrono Avg: ",len(chAvgs))
			
			print("LBLs: ",lbls)
			
			#########################
			# write avgs in csv files
			#########################
			lbl=lbls[0]
			with open(csvPath,  "wb") as fcsv:
				writer = csv.writer(fcsv) 
				writer.writerow([lbl])
				writeCaption(resType, writer)

				
				for i in range(len(evAvgs)):	
				
					if(lbl!=lbls[i]):
						lbl=lbls[i]
						writer.writerow([lbl])
						writeCaption(resType, writer)
					if resType=="cos":
						#import pdb; pdb.set_trace()
						writer.writerow([evAvgs[i],chAvgs[i],N[i],M[i],chunkSizes[i],nStreams[i],blocks[i],grids[i]])	
					elif resType=="mat":
						writer.writerow([evAvgs[i],chAvgs[i],numMat[i],matSize[i],nStreams[i],blocks[i],grids[i]])
					elif resType=="blu":
						writer.writerow([evAvgs[i],chAvgs[i],imgNum[i],sizeImg[i],nStreams[i],blocks[i],grids[i]])
			
			
			
			
####################
### WRITE TO CSV ###
####################
def writeCaption(resType, writer):
	if resType=="cos":
		writer.writerow(['EVENTS','CHRONO','N SIZE','M ITERS','CHUNK','N STREAMS','BLOCK','GRID'])
	elif resType=="mat":
		writer.writerow(['EVENTS','CHRONO','NUM MAT','MAT SIZE','N STREAMS','BLOCK','GRID'])
	elif resType=="blu":
		writer.writerow(['EVENTS','CHRONO','NUM IMG','IMG SIZE','N STREAMS','BLOCK','GRID'])


			
#########################
### GET DATA FROM TXT ###
#########################				
def getCosDatas(str):
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
	#import pdb; pdb.set_trace()
	for line in charsSeq:
		tokens= line.split(',',11)
		lbls.append(tokens[0])
		evTimes.append(float(tokens[1]))
		chronoTimes.append(float(tokens[2]))	
		chunkSizes.append(int(tokens[3]))
		N.append(int(tokens[4]))
		M.append(int(tokens[5]))
		nStreams.append(int(tokens[6]))
		blocks.append(int(tokens[8]))
		grids.append(int(tokens[9]))		

	return lbls, evTimes, chronoTimes, chunkSizes, N, M, nStreams, blocks, grids
	

def getMatDatas(str):
	linesSeq = open(str, 'r')	
	charsSeq = [line.rstrip('\n') for line in linesSeq]
	
	tokens=[]
	lbls=[]
	evTimes=[]
	chronoTimes=[]
	matSize=[]
	numMat=[]
	nStreams=[]
	blocks=[]
	grids=[]
	
	for line in charsSeq:
		tokens= line.split(',',11)
		lbls.append(tokens[0])
		evTimes.append(float(tokens[1]))
		chronoTimes.append(float(tokens[2]))	
		matSize.append(int(tokens[4]))
		numMat.append(int(tokens[5]))
		nStreams.append(int(tokens[6]))
		blocks.append(int(tokens[7]))
		grids.append(int(tokens[8]))		

	return lbls,evTimes,chronoTimes,matSize,numMat,nStreams,blocks,grids
	
	
	
def getBlurDatas(str):
	linesSeq = open(str, 'r')	
	charsSeq = [line.rstrip('\n') for line in linesSeq]
	
	tokens=[]
	lbls=[]
	evTimes=[]
	chronoTimes=[]
	imgNum=[]
	sizeImg=[]
	nStreams=[]
	blocks=[]
	grids=[]
	
	for line in charsSeq:
		tokens= line.split(',',11)
		lbls.append(tokens[0])
		evTimes.append(float(tokens[1]))
		chronoTimes.append(float(tokens[2]))			
		sizeImg.append(int(tokens[3]))
		imgNum.append(int(tokens[4]))
		nStreams.append(int(tokens[5]))
		blocks.append(int(tokens[7]))
		grids.append(int(tokens[8]))		

	return lbls,evTimes,chronoTimes,sizeImg,imgNum,nStreams,blocks,grids
				
				
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


