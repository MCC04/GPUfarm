#!/usr/bin/env python3
# coding=utf-8

#import glob
import os
import matplotlib.pyplot as plt
import numpy as np
import math
import csv



testNum=13
singleResSize = testNum*5*5	

def getDatas(str):
	linesSeq = open(str, 'r')	
	charsSeq = [line.rstrip('\n') for line in linesSeq]
	
	inputParams=[]
	tokens=[]
	evTimes=[]
	chronoTimes=[]

	for line in charsSeq:
		tmp=line[1:]
		if line[:1]=='$': #TOTAL ELAPSED
			tokens= tmp.split(',',2)
			evTimes.append(float(tokens[0]))
			chronoTimes.append(float(tokens[1]))			
		

		elif line[:1]=='#': #INPUT PARAMS
			tokens= tmp.split(',',8)
			if(len(tokens)>2):
				inputParams.append([int(x) for x in tokens[1:]])

	print("\nInput params: ",inputParams)
	print("\nEvent times: ",evTimes)
	print("\nChrono times: ",chronoTimes)


	return inputParams, evTimes, chronoTimes

	
def divideDatas(chronoTimes):
	k=0
	c=0
	ch=np.zeros((5,5))
	maxT=np.zeros((5,5))
	minT=np.zeros((5,5))
	
	for i in range(5):
      		for j in range(5):
      			minT[i][j]=chronoTimes[c]
      			c+=1
	c=0
	while k<13:
      		for i in range(5):
      			for j in range(5):
				if chronoTimes[c]<minT[i][j]:
					minT[i][j]=chronoTimes[c]
					
				if chronoTimes[c]>maxT[i][j]:
					maxT[i][j]=chronoTimes[c]
					
				ch[i][j]+=chronoTimes[c]
				c+=1
		k+=1
	return ch,minT,maxT
	
	
	
	
def getAvgBlur(chronoTimes):
	avg=0

	print("CHRONO BLUR: ",chronoTimes)
	if len(chronoTimes)==testNum:
		chronoTimes.remove(max(chronoTimes))
		chronoTimes.remove(min(chronoTimes))
		avg = sum(chronoTimes)/len(chronoTimes)
	return avg
	
	
def divideDatasInv(chrono):
	k=0
	j=0
	i=0
	
	print("CHRONO DIV DATA INV: ",chrono)
	
	
	avgT=np.zeros((5,5))
	temp=[]
	
	for c in chrono:
		
		if k<testNum:
			temp.append(c)
			k+=1
		else:
			k=0
			temp.remove(max(temp))
			temp.remove(min(temp))
			avgT[i,j]=sum(temp)/len(temp)
			
			temp=[]
			temp.append(c)
			k+=1
		
			if j<(5-1):
				j+=1
			else:
				j=0
				if i<(5-1):
					i+=1
	if len(temp)!=0:
		avgT[4,4]=sum(temp)/len(temp)
	
	return avgT
					

def getAvgTimesInv(chronoTimes):
	i=0
	j=0
	c=0
	ch=[]
	chAvg=[]
	
	for c in chronoTimes:
		if i<13:
			ch.append(c)			
			i+=1
		else:	
			ch.remove(max(ch))
			ch.remove(min(ch))
			tmp = sum(ch)/len(ch)
		
			chAvg.append(tmp)
			ch=[]
			i=0
	return chAvg


def getAvgTimes(chronoTimes,minT,maxT):
	for i in range(5):
		for j in range(5):
			chronoTimes[i][j]-=maxT[i][j]+minT[i][j]
			chronoTimes[i][j]/=(testNum-2)

	return chronoTimes
	


##########
###MAIN###
##########
def main():
	for file in os.listdir("../results/"):
	    if file.endswith(".txt"):
		print(os.path.join("../results/", file))		
	
		
		if file[0:3]=="dev" and file[4:9]!="lowpar":	
			f=os.path.join("../results/", file)
			inputs,evTimes,chronoTimes = getDatas(f)
		
			print("\nEv len: ",len(evTimes))
			print("\nchrono len: ",len(chronoTimes))					
			print("\ninputs len: ",len(inputs))
		
			chAvg=np.zeros((5,5))

				
			if file[4:7]=="cos":
				if file[8:-4]=="invert":
					inv=1

					futureEvAvg=divideDatasInv(evTimes[0:singleResSize])
					streamEvAvg=divideDatasInv(evTimes[singleResSize:(singleResSize*2)])
					managedEvAvg=divideDatasInv(evTimes[(singleResSize*2):(singleResSize*3)])
					
					futureChAvg=divideDatasInv(chronoTimes[0:singleResSize])
					streamChAvg=divideDatasInv(chronoTimes[singleResSize:(singleResSize*2)])
					managedChAvg=divideDatasInv(chronoTimes[(singleResSize*2):(singleResSize*3)])
			
					print("\nFUTURE INV Avg EventTimes : ",futureEvAvg)					
					print("\nSTREAM INV Avg EventTimes : ",streamEvAvg)				
					print("\nMANAGED INV Avg EventTimes : ",managedEvAvg)	
					
					print("\nFUTURE INV Avg chronoTimes : ",futureChAvg)					
					print("\nSTREAM INV Avg chronoTimes : ",streamChAvg)				
					print("\nMANAGED INV Avg chronoTimes : ",managedChAvg)			
									
				else:
					inv=0
					
					futureEvAvg,streamEvAvg,managedEvAvg=avgCosMeasures('Event',evTimes)
					futureChAvg,streamChAvg,managedChAvg=avgCosMeasures('Chrono',chronoTimes)
					
				############
				#LOW PAR COS
				############
				inLowCos,evLowCos,chLowCos=getDatas('../results/dev_lowpar_cos.txt')
				print("\nLowPar COS EventTimes: ",evLowCos)
				print("\nLowPar COS chronoTimes: ",chLowCos)	
				
				futureLowEvAvg,streamLowEvAvg,managedLowEvAvg=avgCosMeasures('Event',evLowCos)
				futureLowChAvg,streamLowChAvg,managedLowChAvg=avgCosMeasures('Chrono',chLowCos)
			
				
				############
				#SPEEDUP
				############				
				#EVENT SPEEDUP
				speedUpEvF = futureLowEvAvg/futureEvAvg
				speedUpEvS = streamLowEvAvg/streamEvAvg
				speedUpEvM = managedLowEvAvg/managedEvAvg
			
				print("\n EVENT speedUpFuture: ",speedUpEvF)
				print("\n EVENT speedUpStream: ",speedUpEvS)
				print("\n EVENT speedUpManaged: ",speedUpEvM)
				
				#CHRONO SPEEDUP
				speedUpChF=futureLowChAvg/futureChAvg
				speedUpChS=streamLowChAvg/streamChAvg
				speedUpChM=managedLowChAvg/managedChAvg
			
				print("\n CHRONO speedUpFuture: ",speedUpChF)
				print("\n CHRONO speedUpStream: ",speedUpChS)
				print("\n CHRONO speedUpManaged: ",speedUpChM)
			
				#############
				#WRITE TO CSV
				#############
				lbl1='FUTURE'
				lbl2='STREAM'
				lbl3='MANAGED'		
				if inv==1:
			
					csvPath="./output/dev_cos_inv.csv"
					lbl1+=' INV'
					lbl2+=' INV'
					lbl3+=' INV'	

			
				else:
					csvPath="./output/dev_cos.csv"
				

				with open(csvPath,  "wb") as fcsv:
				    writer = csv.writer(fcsv)
				    
				    #write event
				    lbl1+=' EVENT'
				    lbl2+=' EVENT'
				    lbl3+=' EVENT'				    
				    writeToCSV(writer,lbl1,futureLowEvAvg,futureEvAvg,speedUpEvF)
				    writeToCSV(writer,lbl2,streamLowEvAvg,streamEvAvg,speedUpChS)
				    writeToCSV(writer,lbl3,managedLowEvAvg,managedEvAvg,speedUpEvM)
				    
				    #write chrono
				    lbl1+=' CHRONO'
				    lbl2+=' CHRONO'
				    lbl3+=' CHRONO'
				    writeToCSV(writer,lbl1,futureLowChAvg,futureChAvg,speedUpChF)
				    writeToCSV(writer,lbl2,streamLowChAvg,streamChAvg,speedUpChS)
				    writeToCSV(writer,lbl3,managedLowChAvg,managedChAvg,speedUpChM)   
			
			
				########################
				####PLOTS ON COS####
				########################
				
				#grafico su comp time anche per inverted, mentre lo speed up solo per la versione normale?
				for i in range(0,5):			
					plotCompTimeGraph(futureEvAvg[i,:], futureEvAvg[:,i],i,file[4:7],inv,0,'Event')
					plotCompTimeGraph(streamEvAvg[i,:], streamEvAvg[:,i],i,file[4:7],inv,0,'Event')
					plotCompTimeGraph(managedEvAvg[i,:], managedEvAvg[:,i],i,file[4:7],inv,0,'Event')
				
							
				#for i in range(0,5):			
					#plotCompTimeGraph(speedUpEvF[i,:], speedUpEvF[:,i],i,file[4:7],inv,1,'Event')
					#plotCompTimeGraph(speedUpEvS[i,:], speedUpEvS[:,i],i,file[4:7],inv,1,'Event')
					#plotCompTimeGraph(speedUpEvM[i,:], speedUpEvM[:,i],i,file[4:7],inv,1,'Event')	
					
				for i in range(0,5):			
					plotSpeedup(speedUpEvF[i,:], speedUpEvF[:,i],i,file[4:7],inv,'Event')
					plotSpeedup(speedUpEvS[i,:], speedUpEvS[:,i],i,file[4:7],inv,'Event')
					plotSpeedup(speedUpEvM[i,:], speedUpEvM[:,i],i,file[4:7],inv,'Event')
					
				#plotSpeedup(y1, y2, num, gType, inv,lblMeasure)	
		

			elif file[4:7]=="mat":
				############
				#LOW PAR MAT
				############
				inLowMat,evLowMat,chLowMat=getDatas('../results/dev_lowpar_mat.txt')
				
								
				#EVENT AVG
				print("\nLowPar MAT EventTimes: ",evLowMat)
				print("\nLowPar Event len: ",len(evLowMat))			
				evLowMm,minLowMm,maxLowMm = divideDatas(evLowMat[0:singleResSize])
				evLowSmm,minLowSmm,maxLowSmm = divideDatas(evLowMat[singleResSize:(singleResSize*2)])
				evLowLsmm,minLowLsmm,maxLowLsmm = divideDatas(evLowMat[(singleResSize*2):(singleResSize*3)])
				
				mmLowEvAvg = getAvgTimes(evLowMm,minLowMm,maxLowMm)
				smmLowEvAvg = getAvgTimes(evLowSmm,minLowSmm,maxLowSmm)
				lsmmLowEvAvg = getAvgTimes(evLowLsmm,minLowLsmm,maxLowLsmm)
				#bbLowEvAvg = getAvgBlur(evLowMat[(singleResSize*3):])				
				
				print("\nmmLowAvg Event AVG: ", mmLowEvAvg)
				print("\nsmmLowAvg Event AVG: ",smmLowEvAvg)
				print("\nlsmmLowAvg Event AVG: ", lsmmLowEvAvg)	
				#print("\nbbLowAvg Event AVG: ", bbLowEvAvg)
						
								
				#CHRONO AVG
				print("\nLowPar MAT chronoTimes: ",chLowMat)
				print("\nLowPar chrono len: ",len(chLowMat))			
				chLowMm,minLowMm,maxLowMm=divideDatas(chLowMat[0:singleResSize])
				chLowSmm,minLowSmm,maxLowSmm=divideDatas(chLowMat[singleResSize:(singleResSize*2)])
				chLowLsmm,minLowLsmm,maxLowLsmm=divideDatas(chLowMat[(singleResSize*2):(singleResSize*3)])
					
				mmLowChAvg = getAvgTimes(chLowMm,minLowMm,maxLowMm)
				smmLowChAvg = getAvgTimes(chLowSmm,minLowSmm,maxLowSmm)
				lsmmLowChAvg = getAvgTimes(chLowLsmm,minLowLsmm,maxLowLsmm)
				#bbLowChAvg=getAvgBlur(chLowMat[(singleResSize*3):])				
				
				print("\nmmLowAvg Chrono AVG: ",mmLowChAvg)
				print("\nsmmLowAvg Chrono AVG: ",smmLowChAvg)
				print("\nlsmmLowAvg Chrono AVG: ",lsmmLowChAvg)	
				#print("\nbbLowAvg Chrono AVG: ",bbLowChAvg)	
				
			
				if file[8:-4]=="invert":				
					inv=1
					
					print("\nLEN ARRAY EventTimes : ",len(evTimes))
					#EVENT AVG AND SPEEDUP
					mmEvAvg=divideDatasInv(evTimes[0:singleResSize])
					smmEvAvg=divideDatasInv(evTimes[singleResSize:(singleResSize*2)])
					lsmmEvAvg=divideDatasInv(evTimes[(singleResSize*2):(singleResSize*3)])
					#bbEvAvg=getAvgBlur(evTimes[(singleResSize*3):])
					print("\nMM INV Avg EventTimes : ",mmEvAvg)
					print("\nSMALL MM INV Avg EventTimes : ",smmEvAvg)
					print("\nLOT SMALL MM INV Avg EventTimes : ",lsmmEvAvg)
					#print("\nBB INV Avg EventTimes : ",bbEvAvg)
				
					speedUpEvMM = mmLowEvAvg/mmEvAvg
					speedUpEvSMM = smmLowEvAvg/smmEvAvg
					speedUpEvLSMM = lsmmLowEvAvg/lsmmEvAvg
					#speedUpEvBB = bbLowEvAvg/bbEvAvg
					print("\nEvent speedUpMM: ",speedUpEvMM)
					print("\nEvent speedUpSMM: ",speedUpEvSMM)
					print("\nEvent speedUpLSMM: ",speedUpEvLSMM)		
					#print("\nEvent speedUpBB: ",speedUpEvBB)
				
										
					
					#CHRONO AVG AND SPEEDUP
					mmChAvg = divideDatasInv(chronoTimes[0:singleResSize])
					smmChAvg = divideDatasInv(chronoTimes[singleResSize:(singleResSize*2)])
					lsmmChAvg = divideDatasInv(chronoTimes[(singleResSize*2):(singleResSize*3)])
					#bbChAvg = getAvgBlur(chronoTimes[(singleResSize*3):])
					print("\nMM INV Avg chronoTimes : ",mmChAvg)
					print("\nSMALL MM INV Avg chronoTimes : ",smmChAvg)
					print("\nLOT SMALL MM INV Avg chronoTimes : ",lsmmChAvg)
					#print("\nBLUR BOX INV Avg chronoTimes : ",bbChAvg)
					
					speedUpChMM = mmLowChAvg/mmChAvg
					speedUpChSMM = smmLowChAvg/smmChAvg
					speedUpChLSMM = lsmmLowChAvg/lsmmChAvg
					#speedUpChBB = bbLowChAvg/bbChAvg
					print("\nspeedUpMM: ",speedUpChMM)
					print("\nspeedUpSMM: ",speedUpChSMM)
					print("\speedUpLSMM: ",speedUpChLSMM)
					#print("\speedUpBB: ",speedUpChBB)	
								
				else:
					inv=0
					#EVENT
					mmEvAvg,smmEvAvg,lsmmEvAvg,bbEvAvg=avgMatMeasures('Event', evTimes)

					speedUpEvMM = mmLowEvAvg/mmEvAvg
					speedUpEvSMM = smmLowEvAvg/smmEvAvg
					speedUpEvLSMM = lsmmLowEvAvg/lsmmEvAvg
					#speedUpEvBB = []
					#speedUpEvBB.append(bbLowEvAvg/bbEvAvg[0])
					#speedUpEvBB.append(bbLowEvAvg/bbEvAvg[1])
					print("\nspeedUpMM: ",speedUpEvMM)
					print("\nspeedUpSMM: ",speedUpEvSMM)
					print("\nspeedUpLSMM: ",speedUpEvLSMM)		
					#print("\nspeedUpBB: ",speedUpEvBB)
					
					
					#CHRONO						
					mmChAvg,smmChAvg,lsmmChAvg,bbChAvg=avgMatMeasures('Chrono', chronoTimes)

					speedUpChMM = mmLowChAvg/mmChAvg
					speedUpChSMM = smmLowChAvg/smmChAvg
					speedUpChLSMM = lsmmLowChAvg/lsmmChAvg
					#speedUpChBB = []
					#speedUpChBB.append(bbLowChAvg/bbChAvg[0])
					#speedUpChBB.append(bbLowChAvg/bbChAvg[1])
					print("\nspeedUpMM: ",speedUpChMM)
					print("\nspeedUpSMM: ",speedUpChSMM)
					print("\nspeedUpLSMM: ",speedUpChLSMM)		
					#print("\nspeedUpBB: ",speedUpChBB)		
						
					
				#WRITE TO CSV
				lbl1='MAT MUL'
				lbl2='SMALL MM'
				lbl3='LOT SMALL MM'
				#lbl4='BLUR BOX'					
				
				if inv==1:			
					csvPath="./output/dev_mat_inv.csv"
					lbl1+=' INV'
					lbl2+=' INV'
					lbl3+=' INV'
					
				else:
					csvPath="./output/dev_mat.csv"
				
				
				with open(csvPath,  "wb") as fcsv:
					writer = csv.writer(fcsv)

					#write event
					lbl1+=' EVENT'
					lbl2+=' EVENT'
					lbl3+=' EVENT'				    
					writeToCSV(writer,lbl1,mmLowEvAvg,mmEvAvg,speedUpEvMM)
					writeToCSV(writer,lbl2,lsmmLowEvAvg,lsmmEvAvg,speedUpEvSMM)
					writeToCSV(writer,lbl3,lsmmLowEvAvg,lsmmEvAvg,speedUpEvLSMM)
					#if inv==0:
					#	lbl4+=' EVENT'	
					#	writeToCSV(writer,lbl4,bbLowEvAvg,bbEvAvg,speedUpEvBB)
					#	writeToCSV(writer,lbl4,bbLowEvAvg,bbEvAvg,speedUpEvBB)

					#write chrono
					lbl1+=' CHRONO'
					lbl2+=' CHRONO'
					lbl3+=' CHRONO'

					writeToCSV(writer,lbl1,mmLowChAvg,mmChAvg,speedUpChMM)
					writeToCSV(writer,lbl2,lsmmLowChAvg,lsmmChAvg,speedUpChSMM)
					writeToCSV(writer,lbl3,lsmmLowChAvg,lsmmChAvg,speedUpChLSMM)
					#if inv==0:
					#	lbl4+=' CHRONO'
					#	writeToCSV(writer,lbl4,bbLowChAvg,bbChAvg,speedUpChBB)
					

					####PLOTS ON MAT####		
			
					#for i in range(0,5):	
						##event		
						#plotCompTimeGraph(speedUpEvMM[i,:], speedUpEvMM[:,i],i,file[4:7],inv,1,' Event')
						#plotCompTimeGraph(speedUpEvLSMM[i,:], speedUpEvLSMM[:,i],i,file[4:7],inv,1,' Event')
						##plotCompTimeGraph(speedUpEvBB[i,:], speedUpEvBB[:,i],i,file[4:7],inv,1,' Event')
						
						##chrono
						#plotCompTimeGraph(speedUpChMM[i,:], speedUpChMM[:,i],i,file[4:7],inv,1,' Chrono')
						#plotCompTimeGraph(speedUpChLSMM[i,:], speedUpChLSMM[:,i],i,file[4:7],inv,1,' Chrono')
						##plotCompTimeGraph(speedUpChBB[i,:], speedUpChBB[:,i],i,file[4:7],inv,1,' Chrono')
		
					#farei il grafico su comp time anche per inverted, mentre lo speed up solo per la versione normale, per adesso
					for i in range(0,5):
						##event			
						plotCompTimeGraph(mmEvAvg[i,:], mmEvAvg[:,i],i,file[4:7],inv,0,' Event')
						plotCompTimeGraph(smmEvAvg[i,:], smmEvAvg[:,i],i,file[4:7],inv,0,' Event')
						plotCompTimeGraph(lsmmEvAvg[i,:], lsmmEvAvg[:,i],i,file[4:7],inv,0,' Event')
						##plotCompTimeGraph(bbEvAvg[i,:], bbEvAvg[:,i],i,file[4:7],inv,0,' Event')
						
						##chrono
						plotCompTimeGraph(mmChAvg[i,:], mmChAvg[:,i],i,file[4:7],inv,0,' Chrono')
						plotCompTimeGraph(smmChAvg[i,:], smmChAvg[:,i],i,file[4:7],inv,0,' Chrono')
						plotCompTimeGraph(lsmmChAvg[i,:], lsmmChAvg[:,i],i,file[4:7],inv,0,' Chrono')
						##plotCompTimeGraph(bbChAvg[i,:], bbChAvg[:,i],i,file[4:7],inv,0,' Chrono')
					
					for i in range(0,5):	
						##event		
						plotSpeedup(speedUpEvMM[i,:], speedUpEvMM[:,i],i,file[4:7],inv,' Event')
						plotSpeedup(speedUpEvLSMM[i,:], speedUpEvLSMM[:,i],i,file[4:7],inv,' Event')
						##plotCompTimeGraph(speedUpEvBB[i,:], speedUpEvBB[:,i],i,file[4:7],inv,1,' Event')
						
						##chrono
						plotSpeedup(speedUpChMM[i,:], speedUpChMM[:,i],i,file[4:7],inv,' Chrono')
						plotSpeedup(speedUpChLSMM[i,:], speedUpChLSMM[:,i],i,file[4:7],inv,' Chrono')
					
					#plotSpeedup(y1, y2, num, gType, inv,lblMeasure)	
						
def avgCosMeasures(label,measures):
	future,minF,maxF=divideDatas(measures[0:singleResSize])
	stream,minS,maxS=divideDatas(measures[singleResSize:(singleResSize*2)])
	managed,minM,maxM=divideDatas(measures[(singleResSize*2):(singleResSize*3)])
	#empty,minEmpty,maxEmpty=divideDatas(measures[(singleResSize*3):])
	
	print("\nFuture ",label," Times: ",future)
	print("\nStream ",label," Times: ",stream)
	print("\nManaged ",label," Times: ",managed)
	
	futureAvg = getAvgTimes(future,minF,maxF)
	streamAvg = getAvgTimes(stream,minS,maxS)
	managedAvg = getAvgTimes(managed,minM,maxM)	

	print("\nFuture ",label," AVG: ", futureAvg)
	print("\nStream ",label," AVG: ",streamAvg)
	print("\nManaged ",label," AVG: ",managedAvg)

	return futureAvg,streamAvg,managedAvg#,emptyAvg


				
def avgMatMeasures(label, measures):

	matmul,minMm,maxMm = divideDatas(measures[0:singleResSize])
	smallmm,minSmm,maxSmm = divideDatas(measures[singleResSize:(singleResSize*2)])
	lotSmallmm,minLotSmm,maxLotSmm = divideDatas(measures[(singleResSize*2):(singleResSize*3)])

	print("\nMatmul ",label," Times: ",matmul)
	print("\nSmallMM ",label," Times: ",smallmm)
	print("\nLotSmallMM ",label," Times: ",lotSmallmm)
							
							
	mmAvg = getAvgTimes(matmul,minMm,maxMm)
	smmAvg = getAvgTimes(smallmm,minSmm,maxSmm)
	lsmmAvg = getAvgTimes(lotSmallmm,minLotSmm,maxLotSmm)

	tmp1 = getAvgBlur(measures[(singleResSize*3):((singleResSize*3)+13)])
	tmp2 = getAvgBlur(measures[((singleResSize*3)+13):])
	bbEvAvg=[]
	bbEvAvg.append(tmp1)
	bbEvAvg.append(tmp2)
	
	print("\nMatMul ",label," AVG: ",mmAvg)
	print("\nSmall MatMul ",label," AVG: ",smmAvg)
	print("\nLotSmall MatMul ",label," AVG: ",lsmmAvg)		
	print("\nBlurBox ",label," AVG: ",bbEvAvg)	
	
	
	return mmAvg,smmAvg,lsmmAvg,bbEvAvg
	
	
def writeToCSV(writer,label,lowAvg,parAvg,spUp):
	if label[0:4]=='BLUR':
		writer.writerow([label,'LOW PAR',lowAvg])
		#writer.writerow(lowAvg)
	
		writer.writerow([label,'AVG'])
		writer.writerow(parAvg)
	
		writer.writerow([label,'SPEEDUP'])
		writer.writerow(spUp)	
	
	else:
	
		writer.writerow([label,'LOW PAR'])
		writer.writerows(lowAvg)
	
		writer.writerow([label,'AVG'])
		writer.writerows(parAvg)
	
		writer.writerow([label,'SPEEDUP'])
		writer.writerows(spUp)	
	
plotId=0
figId=0
	
def plotCompTimeGraph(y1, y2, num, gType, inv, spUp,lblMeasure):

	global plotId	
	global figId		

	if gType=="mat":
		x1=(4,16,32,64,128) #nMat
		x2=(32,64,128,256,512) #dimMat			
		lblx1="N mat"
		lblx2="DIM mat"
	elif gType=="cos":
		x1=(10,50,250,1250,2500)
		x2=(3584,7168,14336,28672,57344)
		lblx1="M"
		lblx2="N"
		
	if spUp==0:
		lbly="Comp Time (ms)" + lblMeasure
		fname= 'comp'
	elif spUp==1:
		lbly="Speed Up" + lblMeasure
		fname = 'spup'
		
	title=str(gType)
	title=title.upper()
	if inv==1:
		title+="-INVERTED"
		fname+='_inv'

	fig=plt.figure(figId)

	ay = fig.add_subplot(111)
	ay.plot(x1, y1, '-', label = lblx1, marker='o', linestyle='-', color='black', linewidth=1)

	ay2 = ay.twiny()
	ay2.plot(x2, y2, '-r', label = lblx2, marker='o', linestyle='-', color='black', linewidth=3)	
	ay2.legend(loc="upper right")
	ay.legend(loc="lower right")
	ay.grid()
	
	ay.set_ylabel(lbly)
	ay.set_xlabel(lblx1)	
	ay2.set_xlabel(lblx2)

	
	ay2.set_xticks(np.linspace(ay2.get_xticks()[0], ay2.get_xticks()[-1], len(ay.get_xticks())))

	plt.suptitle(title,  fontsize=16,horizontalalignment='left')
	plt.tight_layout()
	#plt.show()	
	
	img_name='./plt_img/'+ gType+fname+str(plotId)
	plt.savefig(img_name)
	plotId+=1
	
	figId+=1
	plt.close(fig)
	
	
	
	
	
	
	
	
	
	
def plotSpeedup(y1, y2, num, gType, inv,lblMeasure):			

	global plotId
	global figId
	
	if gType=="mat":
		x1=(4,16,32,64,128) #nMat
		x2=(32,64,128,256,512) #dimMat			
		lblx1="N mat"
		lblx2="DIM mat"
	elif gType=="cos":
		x1=(10,50,250,1250,2500)
		x2=(3584,7168,14336,28672,57344)
		lblx1="M"
		lblx2="N"
		
	#if spUp==0:
	#	lbly="Comp Time (ms)" + lblMeasure
	#elif spUp==1:
	lbly="Speed Up" + lblMeasure
		
	title=str(gType)
	title=title.upper()
	if inv==1:
		title+="-INVERTED"

	plt.figure(figId)

	#ay = fig.add_subplot(111)
	plt.plot(x1, y1, '-', label = 'Speedup', marker='o', linestyle='-', color='black', linewidth=1)
	plt.plot(x1, x1, marker='.',label='Ideal speed up',color='black',linestyle='--')
	plt.xlabel(lblx1)
	plt.ylabel(lbly)
	#ay2 = ay.twiny()
	#ay2.plot(x2, y2, '-r', label = lblx2, marker='o', linestyle='-', color='black', linewidth=3)	
	plt.legend(loc="upper right")
	#ay.legend(loc="lower right")
	#ay.grid()
	
	#ay.set_ylabel(lbly)
	#ay.set_xlabel(lblx1)	
	#ay2.set_xlabel(lblx2)

	
	#ay2.set_xticks(np.linspace(ay2.get_xticks()[0], ay2.get_xticks()[-1], len(ay.get_xticks())))

	plt.suptitle(title,  fontsize=16, horizontalalignment='left')
	plt.tight_layout()
	#plt.show()	
	
	#if inv:
	#	img_name='./plt_img/'+ gType+'Inv_speedup'+lblMeasure+str(num)
	#else:
	#	img_name='./plt_img/'+ gType+'_speedup'+lblMeasure+str(num)
	img_name='./plt_img/'+ gType+'Inv_spup'+str(plotId)
	plt.savefig(img_name)
	plotId+=1
	figId+=1
	plt.close()
	
	plt.figure(figId)
	#ay = fig.add_subplot(111)
	plt.plot(x2, y2, '-', label = lblx2, marker='o', linestyle='-', color='black', linewidth=1)
	plt.plot(x2, x2, marker='.',label='Ideal speed up',color='black',linestyle='--')

	#ay2 = ay.twiny()
	#ay2.plot(x2, y2, '-r', label = lblx2, marker='o', linestyle='-', color='black', linewidth=3)	
	plt.legend(loc="upper right")
	plt.xlabel(lblx2)
	plt.ylabel(lbly)
	#ay.legend(loc="lower right")
	#ay.grid()
	
	#ay.set_ylabel(lbly)
	#ay.set_xlabel(lblx1)	
	#ay2.set_xlabel(lblx2)

	
	#ay2.set_xticks(np.linspace(ay2.get_xticks()[0], ay2.get_xticks()[-1], len(ay.get_xticks())))

	plt.suptitle(title,  fontsize=16, horizontalalignment='left')
	plt.tight_layout()
	#plt.show()
	img_name='./plt_img/'+ gType+'Inv_spup'+str(plotId)
	plt.savefig(img_name)
	plotId+=1
	
	figId+=1
	plt.close()
	
	
	
	
	
	
	
	
	
	
	
	
	
	
if __name__ == "__main__":
	main()









