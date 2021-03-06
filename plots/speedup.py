#!/usr/bin/env python3
# coding=utf-8

import os
import matplotlib.pyplot as plt
import numpy as np
import math
import csv
import sys


cosM=3
cosN=6
dpCosTest = cosM*cosN
strCosTest = cosM*cosN

matSize=5
matNum=4
dpMatTest=6
strMatTest=matSize*matNum

imgSize=3
imgNum=3
dpBlurTest=4
strBlurTest=imgSize*imgNum

##########
###MAIN###
##########
#import pdb; pdb.set_trace()
def main():		
	res_path = "./output/"+sys.argv[1]+"/"
	for file in os.listdir(res_path):
	    if file.endswith("avgs.csv"):
	    	f=os.path.join(res_path, file)
		print(f)		
	
		dataPar=[]
		zeroStream=[]
		threeStream=[]
		coresStream=[]
		
		resType=file[0:3]
		if resType=="cos":
			dataPar,zeroStream,threeStream,coresStream = getDividedData(dpCosTest,strCosTest,f)	
		elif resType=="mat":
			dataPar,zeroStream,threeStream,coresStream = getDividedData(dpMatTest,strMatTest,f)		
		elif resType=="blu":
			dataPar,zeroStream,threeStream,coresStream = getDividedData(dpBlurTest,strBlurTest,f)
		
		zeroThree,zeroCore,coreDp = getSpeedup(zeroStream,threeStream,coresStream,dataPar)
		

		csvPath=res_path+resType+"_sp.csv"
		#write best and speedup
		with open(csvPath,  "wb") as fcsv:
			writer = csv.writer(fcsv) 
		
			printSpToCSV("ZERO/THREE",zeroThree,resType,writer) #num, size, time
			printSpToCSV("ZERO/CORES",zeroCore,resType,writer)
			printSpToCSV("CORES/DATAPAR",coreDp,resType,writer)
			
		#########
		# Plots #
		#########
		# Completion Time
		launchPlots(resType,zeroStream,"Zero Streams")
		launchPlots(resType,threeStream,"Three Streams")
		launchPlots(resType,coresStream,"#SM Streams")
		# Speedup
		#import pdb; pdb.set_trace()
		launchPlots(resType,zeroThree,"Zero/Three")
		launchPlots(resType,zeroCore,"Zero/Cores")
		launchPlots(resType,coresStream,"#SM Streams")
		
	
		streamNums=[]
		if sys.argv[1]=="M40":
			streamNums=[1,3,24]
		elif sys.argv[1]=="P100":
			streamNums=[1,3,56]
			
			
		if resType=="cos":
			plotSpeedup(streamNums, zeroStream, zeroThree, zeroCore, "","",resType,cosN, cosM)	
		elif resType=="mat":
			plotSpeedup(streamNums, zeroStream, zeroThree, zeroCore, "","",resType,matNum, matSize)		
		elif resType=="blu":
			plotSpeedup(streamNums, zeroStream, zeroThree, zeroCore, "","",resType,imgNum, imgSize)
		
		
		
		
		
		
		


def printSpToCSV(label,speedup,resType,writer):
	if resType=="cos":
		writer.writerow(["N","M",label]) #N,M,chunk,str,block,grid
	elif resType=="mat":
		writer.writerow(["#MAT","SIZE",label]) #nMat,size,block,grid		
	elif resType=="blu":
		writer.writerow(["#IMG","SIZE",label]) #imgNum,size			
			
	writer.writerows(speedup)



def getDividedData(dpSize,strSize,filename):
	dataPar=[]
	zeroStr=[]
	threeStr=[]
	coreStr=[]
	
	block=0
	i=0	
	with open(filename) as csv_file:
	    csv_reader = csv.reader(csv_file, delimiter=',')
	    for row in csv_reader:
	    	if len(row)>1 and row[0]!="EVENTS":  		
		    	if block==0:
		    		if i<dpSize:	
		    			dataPar.append([int(row[2]),int(row[3]),float(row[0])]) 
		    			i+=1
		    		else:
		    			i=0
		    			block+=1		
		    	if block==1:
		    		if i<strSize:
		    			zeroStr.append([int(row[2]),int(row[3]),float(row[0])]) 
		    			i+=1
		    		else:
		    			i=0
		    			block+=1		    			
		    	if block==2: 
		    		if i<strSize:
		    			threeStr.append([int(row[2]),int(row[3]),float(row[0])]) 
		    			i+=1
		    		else:
		    			i=0
		    			block+=1	
		 	if block==3:
		    		if i<strSize:
		    			coreStr.append([int(row[2]),int(row[3]),float(row[0])]) 
		    			i+=1	
				else:
					break		
	   
	print("DATAPAR STREAMS: ", dataPar)	 
	print("ZERO STREAMS: ", zeroStr)
	print("THREE STREAMS: ", threeStr)
	print("CORE STREAMS: ", coreStr)
	
	print("DATAPAR LEN: ", len(dataPar))	 
	print("ZERO LEN: ", len(zeroStr))
	print("THREE LEN: ", len(threeStr))
	print("CORE LEN: ", len(coreStr))

	return dataPar,zeroStr,threeStr,coreStr





def getSpeedup(zeroStr,threeStr,coreStr,datapar):
	coreDpSp=[]
	zeroThreeSp=[]
	zeroCoreSp=[]
	i=0
	for i in range(len(zeroStr)):
		val=zeroStr[i][2]/threeStr[i][2]
		#zeroThreeSp.append( [zeroStr[i][0],zeroStr[i][1],zeroStr[i][2],val] )
		zeroThreeSp.append( [zeroStr[i][0],zeroStr[i][1],val] )
		
		val=zeroStr[i][2]/coreStr[i][2]
		zeroCoreSp.append( [zeroStr[i][0],zeroStr[i][1],val] )
		
	i=0
	for i in range(len(datapar)):
		val=coreStr[i][2]/datapar[i][2]
		coreDpSp.append( [datapar[i][0],datapar[i][1],val] )
	
	
	return zeroThreeSp,zeroCoreSp,coreDpSp





	

def launchPlots(resType,compT,lbl):
	if resType=="cos":
		plotCompTimeGraph(compT, lbl+" Completion Time", cosN, cosM, "Item Num (N)", "Ker Iterations (M)",resType)
	elif resType=="mat":
		plotCompTimeGraph(compT, lbl+" Completion Time", matNum, matSize, "Mats Num (Mats)", "Mat Size (N)",resType)	
	#elif resType=="blu":
	#	plotCompTimeGraph(compT, lbl+" Completion Time", imgNum, imgSize, "Images Num (N)", "Images Size (S)")
		
		


plotId=0
figId=0
markers=['v','o','x','^','<','d','*','>']

def plotCompTimeGraph(strCompT, lbl, param1, param2, legT1, legT2,resType):

	global plotId	
	global figId		
	global markers
	
	markNum=len(markers)
	x1=[]
	x2=[]
	y1=[]
	y2=[]
	tmp=[]
	
	t1=[]
	t2=[]


	#title=str(lbl)
	#title=title.upper()
	plt.figure(figId)
	plt.title(lbl)
	
	#import pdb; pdb.set_trace()
	if resType=="cos":
		for i in range(0,len(strCompT),param2):
			tmp=strCompT[i:i+param2]		
			y1.append([row[2] for row in tmp])
			if i<param2:
				x1.append([row[1] for row in tmp])
			t1.append(tmp[0][0])


		for i in range(param2):
			tmp=strCompT[i:len(strCompT):param2]
			y2.append([row[2] for row in tmp])
			if i<param1:
				x2.append([row[0] for row in tmp])
			t2.append(tmp[0][1])
	elif resType=="mat":
	#import pdb; pdb.set_trace()
		for i in range(0,len(strCompT),param1):
			tmp=strCompT[i:i+param1]		
			y1.append([row[2] for row in tmp])
			if i<param1:
				x1.append([row[0] for row in tmp])
			t1.append(tmp[0][1])


		for i in range(param1):
			tmp=strCompT[i:len(strCompT):param1]
			y2.append([row[2] for row in tmp])
			if i<param2:
				x2.append([row[1] for row in tmp])
			t2.append(tmp[0][0])


	x=[]
	y=[]
	i=0
	#j=0
	# Plot on NUMBER
	for y in y1:
		j=i%markNum
		plt.plot(x1[0], y, '-', label = str(t1[i]), marker=markers[j], linestyle='-', linewidth=1)
		i+=1
		#j+=1
	plt.grid(axis='both')
	plt.xticks(x1[0])
	plt.xlabel(legT1)
	plt.xlim(left=-2)
	plt.ylim(bottom=-2)
	plt.ylabel("Milliseconds")	
	plt.legend(loc="upper left",title=legT2)
	plt.show()
	plotId+=1
	figId+=1
		

	x=[]
	y=[]
	i=0
	# Plot on SIZE

	for y in y2:
		j=i%markNum
		plt.plot(x2[0], y, '-', label = str(t2[i]), marker=markers[j], linestyle='-', linewidth=1)
		
		i+=1
		#j+=1
	plt.grid(axis='both')
	plt.xlim(left=-2)
	plt.ylim(bottom=-2)
	plt.xticks(x2[0])
	plt.xlabel(legT2)
	plt.ylabel("Milliseconds")
	plt.legend(loc="upper left",title=legT1)
	plt.show()
	plotId+=1
	figId+=1




	
def plotSpeedup(streamNums,zeroStream, zeroThree , zeroCore, lbl, lblAxis,resType,param1,param2):			

	global plotId
	global figId
	global markers

	title="Speed Up" + lbl		
	title=title.upper()
	
	

	plt.figure(figId)
	plt.plot([0]+streamNums, [0]+streamNums, marker='.',label='Ideal speed up',linestyle='--')

	tmp=[]
	#import pdb; pdb.set_trace()
	#for i in range(len(zeroStream)):
	#	if
	#	j=i%len(markers)
	#	tmp.append(zeroStream[i][2]/zeroStream[i][2])
	#	tmp.append(zeroThree[i][2])
	#	tmp.append(zeroCore[i][2])
	#	plt.plot(streamNums, tmp, '-', label = 'Speedup', marker=markers[j], linestyle='-', linewidth=1)
	#	tmp=[]
	j=0
	lineW=0.5
	alphaVal=1.0
	if resType=="cos":
		indexes=[0, param2-1, len(zeroCore)-param2, len(zeroCore)-1]
		for i in indexes:
			#j=i%len(markers)
			tmp=[1.0, zeroThree[i][2],zeroCore[i][2]]
			lblLine=str(zeroThree[i][0]) +" - "+str(zeroCore[i][1])
			plt.plot(streamNums, tmp, '-', label = lblLine, marker=markers[j], linestyle='-', linewidth=lineW, alpha=alphaVal)
			
			lineW+=0.5
			alphaVal-=0.2
			j+=1
		
	else:
		indexes=[0, param2-1, len(zeroCore)-param2, len(zeroCore)-1]
		for i in indexes:
			#j=i%len(markers)
			tmp=[1.0, zeroThree[i][2],zeroCore[i][2]]
			lblLine=str(zeroThree[i][0]) +" - "+str(zeroCore[i][1])
			plt.plot(streamNums, tmp, '-', label = lblLine, marker=markers[j], linestyle='-', linewidth=lineW, alpha=alphaVal)
			
			lineW+=0.5
			alphaVal-=0.2
			j+=1
	
	
	#for i in range(len(zeroStream)):
	#	j=i%len(markers)
	#	tmp.append(zeroStream[i][2]/zeroStream[i][2])
	#	tmp.append(zeroThree[i][2])
	#	tmp.append(zeroCore[i][2])
	#	plt.plot(streamNums, tmp, '-', label = 'Speedup', marker=markers[j], linestyle='-', linewidth=1)
	#	tmp=[]
	
	plt.xticks(streamNums)
	plt.yticks(streamNums)
	plt.legend(loc="upper left")
	plt.grid(axis='both')
	plt.ylabel("Speedup")
	plt.xlabel("#CUDA Streams")
	plt.show()
	plotId+=1
	figId+=1






	
if __name__ == "__main__":
	main()

































