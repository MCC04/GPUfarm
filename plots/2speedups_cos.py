#!/usr/bin/env python3
# coding=utf-8

import os
import matplotlib.pyplot as plt
import numpy as np
import math
import csv


testNum=8
argsNum=8

##########
###MAIN###
##########
def main():		
	
	#get speedups
	zeroStr, bestStr, sp_zero_best = speedUp('./output/dev_sp_avgs2.csv')
	datapar = speedUpLow('./output/dev_sp_low_avgs2.csv')	
	    
	i=0
	for l in sp_zero_best:
		#l.append(zeroStr[i][3]/bestStrLow[i][4]) #ZERO/LOWHYBR SPEEDUP
		l.append(zeroStr[i][3]/datapar[i][3]) #ZERO/DATAPAR SPEEDUP
		i+=1
		
	i=0
	for l in zeroStr:
		l.append(bestStr[i][4]) #BEST STREAM
		l.append(datapar[i][3]) #DATAPAR 
		i+=1
	

	
	sp_zero_data=[]
	for i in range(len(datapar)):
		if datapar[i][3]!=0:
			sp_zero_data.append(zeroStr[i][3]/datapar[i][3])
	print("ZERO/DATAPAR SPEEDUP: ", sp_zero_data)
	
	
	csvPath="./output/speedups2.csv"
	#write best and speedup
	with open(csvPath,  "wb") as fcsv:
		writer = csv.writer(fcsv) 
		
		#speedup
		writer.writerow(["N","M","#STREAM","BLOCK","ZERO/BEST","ZERO/DATAPAR"]) #N,M,strNum,block
		writer.writerows(sp_zero_best)		
		
		#writer.writerow(["ZERO/HYBR SPEEDUP"])
		#writer.writerow(sp_zero_hybr)
		
		#writer.writerow(["ZERO/LOWHYBR SPEEDUP"])
		#writer.writerow(sp_zero_lowHybr)
		
		#writer.writerow(["ZERO/DATAPAR SPEEDUP"])
		#writer.writerow(sp_zero_data)
		
		#event time
		writer.writerow(["N","M","BLOCK","ZERO STREAMING","BEST STREAM","DATAPAR(1024)"])
		writer.writerows(zeroStr)
		
		#writer.writerow(["BEST STREAMING"])
		#writer.writerows(bestStr)
		
		#writer.writerow(["LOW HYBR STREAMING"])
		#writer.writerows(bestStrLow)
		
		#writer.writerow(["HYBR STREAMING"])
		#writer.writerows(hybrStr)
		
		#writer.writerow(["DATAPAR STREAMING"])
		#writer.writerows(datapar)
		


def speedUpLow(filename):

	dataPar=[]
	bestStr=[]
	
	
	block=0

	strNum=0
	N=0
	M=0	
	minStr=0	
	with open(filename) as csv_file:
	    csv_reader = csv.reader(csv_file, delimiter=',')
	    line_count = 0
	    for row in csv_reader:
	    	if len(row)>1 and row[0]!="EVENTS":  		
	    	
		    	if line_count<10:######
		    		dataPar.append([int(row[3]),int(row[4]),int(row[6]),float(row[0])]) 			   
		    	

			    		
			line_count += 1  
			
	bestStr.append([N,M,strNum,block,minStr])			
	   
	print("DATAPAR STREAMS: ", dataPar)	 
	print("LOW HYBRID BEST STREAMS: ", bestStr)
	
	print("DATAPAR LEN: ", len(dataPar))	 
	print("LOW HYBR LEN: ", len(bestStr))

	speedup=[]
	#for i in range(len(dataPar)):
	#	avg=0
	#	if bestStr[i][4]!=0:
	#		avg=bestStr[i][4]/dataPar[i][3]
	#	speedup.append([bestStr[i][0],avg])

	
	
	#print("SPEEDUP: ", speedup)

	return dataPar#, speedup


def speedUp(filename):

	zeroStr=[]
	bestStr=[]
	hybrStr=[]
		
	block=0
	strNum=0
	N=0
	M=0	
	minStr=0	
	with open(filename) as csv_file:
	    csv_reader = csv.reader(csv_file, delimiter=',')
	    line_count = 0
	    for row in csv_reader:
	    	if len(row)>1 and row[0]!="EVENTS":
		    	#if line_count<50:#####
		    	if int(row[5])==0:
		    		zeroStr.append([int(row[3]),int(row[4]),int(row[6]),float(row[0])]) 			 
		    		
		    		if line_count>1:
		    			 bestStr.append([N,M,strNum,block,minStr])	
		    		strNum=0			
				minStr=float(row[0])
		    	else:
		    		if float(row[0])<minStr:
		    			minStr=float(row[0])			    			
		    			N=int(row[3])
		    			M=int(row[4])
		    			strNum=int(row[5])
		    			block=int(row[6])
			#else:
			#	hybrStr.append([int(row[3]),int(row[4]),int(row[6]),float(row[0])]) #N,M,block,minStr
			line_count += 1  
	
	bestStr.append([N,M,strNum,block,minStr])
				
	   
	print("TIME ZERO STREAMS: ", zeroStr)	 
	print("BEST TIME STREAMS: ", bestStr)
	print("HYBRID TIME STREAMS: ", hybrStr)
	
	print("TIME ZERO LEN: ", len(zeroStr))	 
	print("BEST TIME LEN: ", len(bestStr))
	print("HYBRID TIME LEN: ", len(hybrStr))

	
	speedup=[]
	for i in range(len(zeroStr)):
		avg=0
		if bestStr[i][4]!=0:
			avg=zeroStr[i][3]/bestStr[i][4]
		speedup.append([bestStr[i][0],bestStr[i][1],bestStr[i][2],bestStr[i][3],avg])

	
	
	print("SPEEDUP: ", speedup)

	return zeroStr, bestStr, speedup



	
if __name__ == "__main__":
	main()

































