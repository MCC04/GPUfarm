#!/usr/bin/env python3
# coding=utf-8

#import glob
import os
import matplotlib.pyplot as plt
import numpy as np
import math
import csv

	
def getDatas(str):
	linesSeq = open(str, 'r')	
	charsSeq = [line.rstrip('\n') for line in linesSeq]
	
	inputParams=[]
	tokens=[]
	#evTimes=[]
	chronoTimes=[]

	for line in charsSeq:
		#print line
		#if line[:1]=='*':
		tmp=line[1:]
		if line[:1]=='$': #TOTAL ELAPSED
			tokens= tmp.split(',',2)
			#print tokens
			#if str[-9:]=="oneSm.txt":
			#	evTimes.append(float(tokens[3]))
			#else:
			#	evTimes.append(float(tokens[4])) #Time measured by events

			chronoTimes.append(float(tokens[0]))
		

		elif line[:1]=='#': #INPUT PARAMS
			

			tokens= tmp.split(',',8)
			#print("\nTOK: ",tokens)
			if(len(tokens)>2):
				inputParams.append([int(x) for x in tokens[1:]])
			#inputParams.astype(int)
			#inputParams=[ int(x) for x in inputParams ]
			#print("\nInput params: ")
			#print inputParams
			#if str[-9:]=="oneSm.txt":
			#	evTimes.append(float(tokens[3]))
			#else:
			#	evTimes.append(float(tokens[4])) #Time measured by events
	print("\nInput params: ")
	print(inputParams)
	#print(evTimes)
	print("\nChrono times: ")
	print(chronoTimes)

	return inputParams, chronoTimes

	
#def getAvgTimes(times1, times2):
	
	#l1=[sum(times1[0:3])/4, sum(times1[4:11])/8, sum(times1[12:27])/16 ]
	#l2=[sum(times2[0:3])/4, sum(times2[4:11])/8, sum(times2[12:27])/16 ]
	
	#return l1,l2
	
	
def divideDatas(chronoTimes):
	#i=0
	#j=0
	k=0
	c=0
	#ev=[][]
	ch=np.zeros((5,5))
	maxT=np.zeros((5,5))
	minT=np.zeros((5,5))
	
	for i in range(5):
      		for j in range(5):
      			minT[i][j]=chronoTimes[c]
      			c+=1
	c=0
	while k<13:
		#maxEv=evTimes[c]
		#minEV=evTimes[c]
		#maxT=np.zeros((5,5))
		#minT=np.zeros((5,5))
		#i=0
		#j=0
		#for (i=0;i<5;i++)
      			#for (j=0;j<5;j++)
      		for i in range(5):
      			for j in range(5):
		#while i<5:
			#while j<5:
				#ev[i,j]+=evTimes[c]
				if chronoTimes[c]<minT[i][j]:
					minT[i][j]=chronoTimes[c]
					
				if chronoTimes[c]>maxT[i][j]:
					maxT[i][j]=chronoTimes[c]
					
				ch[i][j]+=chronoTimes[c]
				c+=1
				#j+=1
			#i+=1
		k+=1
	#ev[:][:]/=12
	#ch=ch/12
	return ch,minT,maxT
	
	
	
	
def getAvgBlur(chronoTimes):
	#i=0
	#j=0
	avg=0
	#c=0
	#ev=[][]
	#ch=np.zeros((5,5))
	#maxT=np.zeros((5,5))
	#minT=np.zeros((5,5))
	print("CHRONO BLUR: ",chronoTimes)
	if len(chronoTimes)==testNum:
		chronoTimes.remove(max(chronoTimes))
		chronoTimes.remove(min(chronoTimes))
		avg = sum(chronoTimes)/len(chronoTimes)
	return avg
#def divideDatasInv(avgTimes):
	#i=0
	#j=0
	#c=0
	#avgT=np.zeros((5,5))
	
	#for i in range(5):
		#for j in range(5):
		#	avgT[i][j]=avgTimes[c]
		#	c+=1
	
	#return avgT
	
	
	
def divideDatasInv(chrono):
	k=0
	j=0
	i=0
	#count=1
	
	avgT=np.zeros((5,5))
	#temp=np.zeros(testNum)
	temp=[]
	
	for c in chrono:
		
		if k<testNum:
			#print(k)
			temp.append(c)
			k+=1
			
		#elif k>=testNum or count>=len(chrono):
		else:
			k=0
			temp.remove(max(temp))
			temp.remove(min(temp))
			#print("i: ",i,"j: ",j)
			#print("temp: ",temp)
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
		#count+=1
	print("avgT: ", avgT)
	print("Last temp: ", temp)
	avgT[4,4]=sum(temp)/len(temp)
	
	return avgT
	
	
def divideInputMat(inputs):
	k=0
	c=0

	matDim=np.zeros((5,5))
	matNum=np.zeros((5,5))
	minT=np.zeros((5,5))
	
	for i in range(5):
      		for j in range(5):
      			minT[i][j]=chronoTimes[c]
      			c+=1
	c=0
	while k<13:
		#maxEv=evTimes[c]
		#minEV=evTimes[c]
		#maxT=np.zeros((5,5))
		#minT=np.zeros((5,5))
		#i=0
		#j=0
		#for (i=0;i<5;i++)
      			#for (j=0;j<5;j++)
      		for i in range(5):
      			for j in range(5):
		#while i<5:
			#while j<5:
				#ev[i,j]+=evTimes[c]
				if chronoTimes[c]<minT[i][j]:
					minT[i][j]=chronoTimes[c]
					
				if chronoTimes[c]>maxT[i][j]:
					maxT[i][j]=chronoTimes[c]
					
				ch[i][j]+=chronoTimes[c]
				c+=1
				#j+=1
			#i+=1
		k+=1
	#ev[:][:]/=12
	#ch=ch/12
	return ch,minT,maxT












	i=0
	j=0
	c=0
	avgT=np.zeros((5,5))
	
	for i in range(5):
		for j in range(5):
			avgT[i][j]=avgTimes[c]
			c+=1
	
	return avgT	
	
	
def divideInputCos(inputs):
	i=0
	j=0
	c=0
	avgT=np.zeros((5,5))
	
	for i in range(5):
		for j in range(5):
			avgT[i][j]=avgTimes[c]
			c+=1
	
	return avgT	
	
	
	

testNum=13					

def getAvgTimesInv(chronoTimes):

	i=0
	j=0
	c=0
	#ev=[][]
	#ch=[][]
	ch=[]

	chAvg=[]
	for c in chronoTimes:
		if i<13:
			#ev.append(e)
			ch.append(c)			
			i+=1
		#tmp=getAvgTimes2(ch)
		
		#print("\nch temp vect: ")
		#print(ch)
		else:	
			ch.remove(max(ch))
			ch.remove(min(ch))

			tmp = sum(ch)/len(ch)
		
		
		
			#eAvg.append(tmp1)
			chAvg.append(tmp)
			#ev=[]
			ch=[]
			i=0
	return chAvg


def getAvgTimes(chronoTimes,minT,maxT):


	for i in range(5):
		for j in range(5):
			chronoTimes[i][j]-=maxT[i][j]+minT[i][j]
			chronoTimes[i][j]/=(testNum-2)
	#evTimes.remove(max(evTimes))
	#evTimes.remove(min(evTimes))

	#chronoTimes.remove(max(chronoTimes))
	#chronoTimes.remove(min(chronoTimes))

	#eventAvg = sum(evTimes)/len(evTimes)
	#chronoAvg = sum(chronoTimes)/len(chronoTimes)
		
	
		
	return chronoTimes
	

	
singleResSize = testNum*5*5
##########
###MAIN###
##########
def main():
	#path = '../results/'

	#files = [f for f in glob.glob(path + "**/*.txt", recursive=True)]
	
	counter=1

	for file in os.listdir("../results/"):
	    if file.endswith(".txt"):
		print(os.path.join("../results/", file))
		
	
		
		if file[0:3]=="dev" and file[4:9]!="lowpar":					
							
			#questa regione è uguale in host	
			f=os.path.join("../results/", file)
			inputs,chronoTimes = getDatas(f)
		
		
		
			print("\nchrono len: ")
			print(len(chronoTimes))
		
			print("\ninputs len: ")
			print(len(inputs))
			#
		
			chAvg=np.zeros((5,5))
		
				#if f[4:-4]=="cos":
				
			#print("\nf[4:7]: ", f[4:7])
				
			#print("\nf[8:-4]: ", f[8:-4])	
				
			if file[4:7]=="cos":
				if file[8:-4]=="invert":
					inv=1
					#chVectAvg=getAvgTimesInv(chronoTimes)
			
					#print(half)
					#print(chronoTimes[:half])
					#print(chronoTimes[half:])
					futureAvg=divideDatasInv(chronoTimes[0:singleResSize])
					streamAvg=divideDatasInv(chronoTimes[singleResSize:(singleResSize*2)])
					managedAvg=divideDatasInv(chronoTimes[(singleResSize*2):(singleResSize*3)])
			
					#chSeqAvg=divideDatasInv(chronoTimes[:half])
					#chParAvg=divideDatasInv(chronoTimes[half:])
			
					#divideDatasInv(chronoTimes)
					#chronoTimes.append(float(tokens[0]))
					print("\nFUTURE INV Avg chronoTimes : ")
					print(futureAvg)
					print("\nSTREAM INV Avg chronoTimes : ")
					print(streamAvg)
					print("\nMANAGED INV Avg chronoTimes : ")
					print(managedAvg)
					
					
					
					
					
					
					
					
					
					
					
					
				else:
					inv=0
					#chunk = len(chronoTimes)//2
					chFuture,minFuture,maxFuture=divideDatas(chronoTimes[0:singleResSize])
					chStream,minStream,maxStream=divideDatas(chronoTimes[singleResSize:(singleResSize*2)])
					chManaged,minManaged,maxManaged=divideDatas(chronoTimes[(singleResSize*2):(singleResSize*3)])
					#chEmpty,minEmpty,maxEmpty=divideDatas(chronoTimes[(singleResSize*3):])
					print("\nFuture chronoTimes: ")
					print(chFuture)	
					print("\nStream chronoTimes: ")
					print(chStream)
					print("\nManaged chronoTimes: ")
					print(chManaged)
					print("\nEmpty chronoTimes: ")
					#print(chEmpty)
							
					futureAvg = getAvgTimes(chFuture,minFuture,maxFuture)
					streamAvg = getAvgTimes(chStream,minStream,maxStream)
					managedAvg = getAvgTimes(chManaged,minManaged,maxManaged)
					#emptyAvg = getAvgTimes(chEmpty,minEmpty,maxEmpty)
				
					print("\nFuture Chrono AVG: ")
					print(futureAvg)
					print("\nStream Chrono AVG: ")
					print(streamAvg)
					print("\nManaged Chrono AVG: ")
					print(managedAvg)			
					#print("\nEmpty Chrono AVG: ")
					#print(emptyAvg)
			
			
				#COMPUTE SPEEDUP
				inLowCos,chLowCos=getDatas('../results/dev_lowpar_cos.txt')
				print("\nLowPar COS chronoTimes: ")
				print(chLowCos)
				chLowFuture,minLowFuture,maxLowFuture=divideDatas(chLowCos[0:singleResSize])
				chLowStream,minLowStream,maxLowStream=divideDatas(chLowCos[singleResSize:(singleResSize*2)])
				chLowManaged,minLowManaged,maxLowManaged=divideDatas(chLowCos[(singleResSize*2):])
							
				futureLowAvg = getAvgTimes(chLowFuture,minLowFuture,maxLowFuture)
				streamLowAvg = getAvgTimes(chLowStream,minLowStream,maxLowStream)
				managedLowAvg = getAvgTimes(chLowManaged,minLowManaged,maxLowManaged)
				#emptyAvg = getAvgTimes(chEmpty,minEmpty,maxEmpty)
				
				print("\nfutureLowAvg Chrono AVG: ")
				print(futureLowAvg)
				print("\nstreamLowAvg Chrono AVG: ")
				print(streamLowAvg)
				print("\nmanagedLowAvg Chrono AVG: ")
				print(managedLowAvg)	
				

				speedUpFuture=futureLowAvg/futureAvg
				speedUpStream=streamLowAvg/streamAvg
				speedUpManaged=managedLowAvg/managedAvg
			
				print("\nspeedUpFuture: ")
				print(speedUpFuture)
				print("\nspeedUpStream: ")
				print(speedUpStream)
				print("\nspeedUpManaged: ")
				print(speedUpManaged)
				
				
				
				
				if inv==1:
					with open("./output/dev_cos_inv.csv",  "wb") as fcsv:
					    writer = csv.writer(fcsv)
					    #writeToCsv()
					    writer.writerow(['FUTURE INV','LOW PAR'])
					    writer.writerows(futureLowAvg)
					    writer.writerow(['FUTURE INV','AVG'])
					    writer.writerows(futureAvg)
					    writer.writerow(['FUTURE INV','SPEEDUP'])
					    writer.writerows(speedUpFuture)
					    
					    writer.writerow(['STREAM INV','LOW PAR'])
					    writer.writerows(streamLowAvg)
					    writer.writerow(['STREAM INV','AVG'])
					    writer.writerows(streamAvg)
					    writer.writerow(['STREAM INV','SPEEDUP'])
					    writer.writerows(speedUpStream)
					    
					    writer.writerow(['MANAGED INV','LOW PAR'])
					    writer.writerows(managedLowAvg)
					    writer.writerow(['MANAGED INV','AVG'])
					    writer.writerows(managedAvg)
					    writer.writerow(['MANAGED INV','SPEEDUP'])
					    writer.writerows(speedUpManaged)
				
				else:

					with open("./output/dev_cos.csv",  "wb") as fcsv:
					    writer = csv.writer(fcsv)
					    #writeToCsv()
					    #if inv==0:
					    	#writer.writerow(['FUTURE','LOW PAR'])
					   # else:
					    writer.writerow(['FUTURE','LOW PAR','INVERT'])
					    writer.writerows(futureLowAvg)
					    writer.writerow(['FUTURE','AVG'])
					    writer.writerows(futureAvg)
					    writer.writerow(['FUTURE','SPEEDUP'])
					    writer.writerows(speedUpFuture)
					    
					    writer.writerow(['STREAM','LOW PAR'])
					    writer.writerows(streamLowAvg)
					    writer.writerow(['STREAM','AVG'])
					    writer.writerows(streamAvg)
					    writer.writerow(['STREAM','SPEEDUP'])
					    writer.writerows(speedUpStream)
					    
					    writer.writerow(['MANAGED','LOW PAR'])
					    writer.writerows(managedLowAvg)
					    writer.writerow(['MANAGED','AVG'])
					    writer.writerows(managedAvg)
					    writer.writerow(['MANAGED','SPEEDUP'])
					    writer.writerows(speedUpManaged)
			
			
			
				####PLOTS ON COS####			
				for i in range(0,5):			
					plotCompTimeGraph(speedUpFuture[i,:], speedUpFuture[:,i],i,file[4:7],inv,1)
					plotCompTimeGraph(speedUpStream[i,:], speedUpStream[:,i],i,file[4:7],inv,1)
					plotCompTimeGraph(speedUpManaged[i,:], speedUpManaged[:,i],i,file[4:7],inv,1)
		
				#farei il grafico su comp time anche per inverted, mentre lo speed up solo per la versione normale, per adesso
				for i in range(0,5):			
					plotCompTimeGraph(futureAvg[i,:], futureAvg[:,i],i,file[4:7],inv,0)
					plotCompTimeGraph(streamAvg[i,:], streamAvg[:,i],i,file[4:7],inv,0)
					plotCompTimeGraph(managedAvg[i,:], managedAvg[:,i],i,file[4:7],inv,0)
			
				
								
				
				
				
				#elif f[4:-4]=="mat":
			elif file[4:7]=="mat":
			
				inLowMat,chLowMat=getDatas('../results/dev_lowpar_mat.txt')
				print("\nLowPar MAT chronoTimes: ")
				print(chLowMat)
				print("\nLowPar chrono len: ")
				print(len(chLowMat))				
				chLowMm,minLowMm,maxLowMm=divideDatas(chLowMat[0:singleResSize])
				chLowSmm,minLowSmm,maxLowSmm=divideDatas(chLowMat[singleResSize:(singleResSize*2)])
				chLowLsmm,minLowLsmm,maxLowLsmm=divideDatas(chLowMat[(singleResSize*2):(singleResSize*3)])
				#chLowBb,minLowBb,maxLowBb=divideDatas(chLowMat[(singleResSize*3):])
				
							
				mmLowAvg = getAvgTimes(chLowMm,minLowMm,maxLowMm)
				smmLowAvg = getAvgTimes(chLowSmm,minLowSmm,maxLowSmm)
				lsmmLowAvg = getAvgTimes(chLowLsmm,minLowLsmm,maxLowLsmm)
				#bbLowAvg = getAvgTimes(chLowBb,minLowBb,maxLowBb)
				bbLowAvg=getAvgBlur(chLowMat[(singleResSize*3):])
				
				
				print("\nmmLowAvg Chrono AVG: ")
				print(mmLowAvg)
				#print("\nsmmLowAvg Chrono AVG: ")
				#print(smmLowAvg)
				print("\nlsmmLowAvg Chrono AVG: ")
				print(lsmmLowAvg)	
				print("\nbbLowAvg Chrono AVG: ")
				print(bbLowAvg)	
			
				if file[8:-4]=="invert":
					#if f[4:-4]=="mat_invert":
				
					inv=1
					#chVectAvg=getAvgTimesInv(chronoTimes)
			
					#print(half)
					#print(chronoTimes[:half])
					#print(chronoTimes[half:])
			
					mmAvg=divideDatasInv(chronoTimes[0:singleResSize])
					smmAvg=divideDatasInv(chronoTimes[singleResSize:(singleResSize*2)])
					lsmmAvg=divideDatasInv(chronoTimes[(singleResSize*2):])
			
					#divideDatasInv(chronoTimes)
					#chronoTimes.append(float(tokens[0]))
					print("\nMM INV Avg chronoTimes : ")
					print(mmAvg)
					print("\nSMALL MM INV Avg chronoTimes : ")
					print(smmAvg)
					print("\nLOT SMALL MM INV Avg chronoTimes : ")
					print(lsmmAvg)	
				
				
				
				
					speedUpMM = mmLowAvg/mmAvg
					speedUpSMM = smmLowAvg/smmAvg
					speedUpLSMM = lsmmLowAvg/lsmmAvg
					#speedUpBB = bbLowAvg/bbAvg
					print("\nspeedUpMM: ")
					print(speedUpMM)
					print("\nspeedUpSMM: ")
					print(speedUpSMM)
					print("\speedUpLSMM: ")
					print(speedUpLSMM)		
					#print("\nspeedUpBB: ")
					#print(speedUpBB)
					
					
					
					with open("./output/dev_mat_inv.csv",  "wb") as fcsv:
						writer = csv.writer(fcsv)
					    	#writeToCsv()	    

										
						writer.writerow(['MAT MUL INV','LOW PAR'])
						writer.writerows(mmLowAvg)
						writer.writerow(['MAT MUL INV','AVG'])
						writer.writerows(mmAvg)
						writer.writerow(['MAT MUL INV','SPEEDUP'])
						writer.writerows(speedUpMM)
	

						writer.writerow(['SMALL MM INV','LOW PAR'])
						writer.writerows(smmLowAvg)
						writer.writerow(['SMALL MM INV','AVG'])
						writer.writerows(smmAvg)
						writer.writerow(['SMALL MM INV','SPEEDUP'])
						writer.writerows(speedUpSMM)

						writer.writerow(['LOT SMALL MM INV','LOW PAR'])
						writer.writerows(lsmmLowAvg)
						writer.writerow(['LOT SMALL MM INV','AVG'])
						writer.writerows(lsmmAvg)
						writer.writerow(['LOT SMALL MM INV','SPEEDUP'])
						writer.writerows(speedUpLSMM)		 
					
									
								
				else:
					inv=0
					chMatmul,minMm,maxMm = divideDatas(chronoTimes[0:singleResSize])
					chSmallmm,minSmm,maxSmm = divideDatas(chronoTimes[singleResSize:(singleResSize*2)])
					chLotSmallmm,minLotSmm,maxLotSmm = divideDatas(chronoTimes[(singleResSize*2):(singleResSize*3)])
					#chBlurbox,minBlurbox,maxBlurbox = divideDatas(chronoTimes[(singleResSize*3):])
			
					print("\nMatmul chronoTimes: ")
					print(chMatmul)	
					print("\nSmallMM chronoTimes: ")
					print(chSmallmm)
					print("\nLotSmallMM chronoTimes: ")
					print(chLotSmallmm)
					#print("\nBlurbox chronoTimes: ")
					#print(chBlurbox)
											
											
					mmAvg = getAvgTimes(chMatmul,minMm,maxMm)
					smmAvg = getAvgTimes(chSmallmm,minSmm,maxSmm)
					lsmmAvg = getAvgTimes(chLotSmallmm,minLotSmm,maxLotSmm)
					#bbAvg = getAvgTimes(chBlurbox,minBlurbox,maxBlurbox)
					tmp1 = getAvgBlur(chronoTimes[(singleResSize*3):((singleResSize*3)+13)])
					tmp2 = getAvgBlur(chronoTimes[((singleResSize*3)+13):])
					bbAvg=[]
					bbAvg.append(tmp1)
					bbAvg.append(tmp2)
					print("\nMatMul Chrono AVG: ")
					print(mmAvg)
					print("\nSmall MatMul Chrono AVG: ")
					print(smmAvg)
					print("\nLotSmall MatMul Chrono AVG: ")
					print(lsmmAvg)			
					print("\nBlurBox Chrono AVG: ")
					print(bbAvg)
			
			
			

					speedUpMM = mmLowAvg/mmAvg
					speedUpSMM = smmLowAvg/smmAvg
					speedUpLSMM = lsmmLowAvg/lsmmAvg
					speedUpBB = []
					speedUpBB.append(bbLowAvg/bbAvg[0])
					speedUpBB.append(bbLowAvg/bbAvg[1])
					print("\nspeedUpMM: ")
					print(speedUpMM)
					print("\nspeedUpSMM: ")
					print(speedUpSMM)
					print("\nspeedUpLSMM: ")
					print(speedUpLSMM)		
					print("\nspeedUpBB: ")
					print(speedUpBB)			
					
					
					with open("./output/dev_mat.csv",  "wb") as fcsv:
						writer = csv.writer(fcsv)
					    	#writeToCsv()	    

										
						writer.writerow(['MAT MUL','LOW PAR'])
						writer.writerows(mmLowAvg)
						writer.writerow(['MAT MUL','AVG'])
						writer.writerows(mmAvg)
						writer.writerow(['MAT MUL','SPEEDUP'])
						writer.writerows(speedUpMM)
	

						writer.writerow(['SMALL MM','LOW PAR'])
						writer.writerows(smmLowAvg)
						writer.writerow(['SMALL MM','AVG'])
						writer.writerows(smmAvg)
						writer.writerow(['SMALL MM','SPEEDUP'])
						writer.writerows(speedUpSMM)

						writer.writerow(['LOT SMALL MM','LOW PAR'])
						writer.writerows(lsmmLowAvg)
						writer.writerow(['LOT SMALL MM','AVG'])
						writer.writerows(lsmmAvg)
						writer.writerow(['LOT SMALL MM','SPEEDUP'])
						writer.writerows(speedUpLSMM)		 
					
						#if inv==0:			   
						writer.writerow(['BLUR BOX','LOW PAR',bbLowAvg])
						#writer.writerows(bbLowAvg)
						writer.writerow(['BLUR BOX','AVG',bbAvg])
						#writer.writerows(bbAvg)
						writer.writerow(['BLUR BOX','SPEEDUP',speedUpBB])
						#writer.writerows(speedUpBB)
					
					
						
						
					####PLOTS ON MAT####		
			
					for i in range(0,5):			
						plotCompTimeGraph(speedUpMM[i,:], speedUpMM[:,i],i,file[4:7],inv,1)
						plotCompTimeGraph(speedUpLSMM[i,:], speedUpLSMM[:,i],i,file[4:7],inv,1)
						#plotCompTimeGraph(speedUpBB[i,:], speedUpBB[:,i],i,file[4:7],inv,1)
		
					#farei il grafico su comp time anche per inverted, mentre lo speed up solo per la versione normale, per adesso
					for i in range(0,5):			
						plotCompTimeGraph(mmAvg[i,:], mmAvg[:,i],i,file[4:7],inv,0)
						plotCompTimeGraph(smmAvg[i,:], smmAvg[:,i],i,file[4:7],inv,0)
						plotCompTimeGraph(lsmmAvg[i,:], lsmmAvg[:,i],i,file[4:7],inv,0)
						#plotCompTimeGraph(bbAvg[i,:], bbAvg[:,i],i,file[4:7],inv,0)
					
						
								
				#chSeqAvg = getAvgTimes(chSeq,minSeqT,maxSeqT)
				#chParAvg = getAvgTimes(chPar,minParT,maxParT)
					
				#print("\nSEQ Chrono AVG: ")
				#print(chSeq)			
				#print("\nPAR Chrono AVG: ")
				#print(chPar)
				
				
				#chLowMat=getDatas('../results/dev_lowpar_mat.txt')	
				#print("\nLowPar MAT chronoTimes: ")
				#print(chLowMat)
								
				#futureLowAvg = getAvgTimes(chFuture,minFuture,maxFuture)
				#streamLowAvg = getAvgTimes(chStream,minStream,maxStream)
				#manageLowdAvg = getAvgTimes(chManaged,minManaged,maxManaged)
				#emptyAvg = getAvgTimes(chEmpty,minEmpty,maxEmpty)
					
				#print("\nFuture Chrono AVG: ")
				#print(futureAvg)
				#print("\nStream Chrono AVG: ")
				#print(streamAvg)
			
	
				#speedUp=chSeq/chPar
				#print("\nSpeedup: ")
				#print(speedUp)
				#break
			
			
			
			
			
			
		
			
			
			
			
			
			
			
			
			
			
			
				

				
				
				
				
				
				
				
				
			
			
			
			#elif file[5:8]=="cos":
				#N=(3584,7168,14336,28672,57344)
				#M=(10,50,250,1250,2500)		
				
				#fig=plt.figure(2)
	
				#ay = fig.add_subplot(111)
	
				#ay.plot(M, chParAvg[0,:], '-', label = 'M')
				#ay.legend(loc=1)

				#ay2 = ay.twiny()
				#ay2.plot(N, chParAvg[:,0], '-r', label = 'N')
				#ay2.legend(loc=0)
				#ay.grid()
				#ay.set_xlabel("M")
				#ay.set_ylabel("Comp Time (ms)")
				#ay2.set_ylabel("N")
			
				#plt.show()
	
	
	
	
	
	
	
				#plt.plot(iterNum, f1[5:10], marker='.',label='Future')
	
				#plt.plot(iterNum, s1[5:10], marker='.',label='Stream ')

				#plt.plot(iterNum, m1[5:10], marker='.',label='Managed')
				#plt.xlabel('ELEM NUMBER')
				#plt.ylabel('EVENT ELAPSED 3584 ELEMS \n (ms)')
	
				#plt.xscale('log',basex=2)
				#plt.xticks(iterNum)
				#plt.xscale('log',basex=5)
				#plt.legend(loc='upper left')
				#plt.grid()
				#plt.show()
				
	
	
	
	
	
	
	
	
def plotCompTimeGraph(y1, y2, num, gType, inv, spUp):			

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
		lbly="Comp Time (ms)"
		
		#x1=(4,16,32,64,128) #nMat
		#x2=(32,64,128,256,512) #dimMat			
		#lblx1="N mat"
		#lblx2="DIM mat"
	elif spUp==1:
		lbly="Speed Up"
		#x1=(10,50,250,1250,2500)
		#x2=(3584,7168,14336,28672,57344)
		#lblx1="M"
		#lblx2="N"
		
	title=str(gType)
	title=title.upper()
	if inv==1:
		title+="-INVERTED"
	#elif inv==0:
		#title=""
		
		
	fig=plt.figure(num)

	ay = fig.add_subplot(111)
	
	#print("y1: ",y1)
	#print("y2: ",y2)

	ay.plot(x1, y1, '-', label = lblx1, marker='x', linestyle='-', color='black', linewidth=1)
	
		
	
	#ay.set_yticks(y1)
	
	#ay.plot(time, Rn, '-', label = 'Rn')
	#plt.ylim(y1[0], y1[-1])
	ay2 = ay.twiny()
	
	
	
	#if spUp==1:
		#ay.plot(x1, x1, label = 'ideal', linestyle=':', color='black')
		#ay.set_ylim(y1[0], y1[-1]*20)
		#ay.set_yticks(y1)
		#ay2.set_ylim(y2[0], y2[-1])
		#ay2.set_yticks(y2)
	ay2.plot(x2, y2, '-r', label = lblx2, marker='x', linestyle='-', color='black', linewidth=3)	
	ay2.legend(loc="upper right")
	ay.legend(loc="lower right")
	ay.grid()
	ay.set_ylabel(lbly)
	ay.set_xlabel(lblx1)
	#ay.set_xticks(x1,['1','2','3','4','5','6'])	
	#ay.set_xticks(np.linspace(ay.get_yticks()[0], ay.get_yticks()[-1], len(ay2.get_yticks())))
	#ay.xaxis.set_ticklabels(x1)
	#ay.set_xlim(0, ay.get_xticks()[-1])
	
	#ay2.set_xticks(x2,['1','2','3','4','5'])
	#ay2.xaxis.set_ticklabels(x2)		
	ay2.set_xlabel(lblx2)
	#ay2.set_ylim(ay2.get_yticks()[0], ay2.get_yticks()[-1])
	#ay2.set_xlim(0, ay2.get_xticks()[-1])
	
	ay2.set_xticks(np.linspace(ay2.get_xticks()[0], ay2.get_xticks()[-1], len(ay.get_xticks())))
	
	
	#ay2.grid(None)
	#ay2.set_ylim(0, 35)
	#ay.set_ylim(-20,100)
	#plt.xscale('log',basex=5)
	plt.suptitle(title,  fontsize=16)
	plt.tight_layout()
	plt.show()	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
				
#def plotCompTimeGraph(y1,y2,num,gType,spUp):			

	#if gType=="mat":
	#	x1=(4,16,32,64,128) #nMat
	#	x2=(32,64,128,256,512) #dimMat			
	#	lblx1="N mat"
	#	lblx2="DIM mat"
	#elif gType=="cos":
	#	x1=(10,50,250,1250,2500)
	#	x2=(3584,7168,14336,28672,57344)
	#	lblx1="M"
	#	lblx2="N"
		
	#if spUp==0:
	#	lbly="Comp Time (ms)"
		
		
	#elif spUp==1:
		#lbly="Speed Up"
		
		
	#fig=plt.figure(num)

	#ay = fig.add_subplot(111)

	#ay.plot(x1, y1, '-', label = lblx1)
	#ay.legend(loc=1)

	#ay2 = ay.twiny()
	#ay2.plot(x2, y2, '-r', label = lblx2)
	#ay2.legend(loc=0)
	#ay.grid()
	#ay.set_ylabel(lbly)
	#ay.set_xlabel(lblx1)		
	#ay2.set_ylabel(lblx2)
	
	#plt.show()



	
if __name__ == "__main__":
	main()









