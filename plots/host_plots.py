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
	chronoTimes=[]

	for line in charsSeq:
		tmp=line[1:]
		if line[:1]=='$': #TOTAL ELAPSED
			tokens= tmp.split(',',2)
			chronoTimes.append(float(tokens[0]))		

		elif line[:1]=='#': #INPUT PARAMS			
			tokens= tmp.split(',',8)
			if(len(tokens)>1):
				inputParams.append([int(x) for x in tokens[1:]])

	print("\nInput params: ")
	print(inputParams)
	print("\nChrono times: ")
	print(chronoTimes)

	return inputParams, chronoTimes

	
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
	
def divideDatasInv(chrono):
	k=0
	j=0
	i=0	
	avgT=np.zeros((5,5))
	temp=[]
	
	for c in chrono:
		
		if k<testNum:
			#print(k)
			temp.append(c)
			k+=1

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
	avgT[4,4]=sum(temp)/len(temp)
	
	return avgT
	


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
		
		if file[0:4]=="host": 
			f=os.path.join("../results/", file)
			inputs,chronoTimes = getDatas(f)
						
			
			print("\nchrono len: ",len(chronoTimes))
			print("\ninputs len: ",len(inputs))
			
			
			



			if file[5:8]=="mat":  
			
			
			
			
			
			
				chAvg=np.zeros((5,5))
				part = len(chronoTimes)//4
		
				if file[-10:]=="invert.txt":
					inv=1
								
					chMMSeqAvg=divideDatasInv(chronoTimes[0:part])
					chMMParAvg=divideDatasInv(chronoTimes[part:(part*2)])				
					chLMMSeqAvg=divideDatasInv(chronoTimes[(part*2):(part*3)])
					chLMMParAvg=divideDatasInv(chronoTimes[(part*3):(part*4)])
				
				
					print("\nMATMUL SEQ INV Avg chronoTimes : ", chMMSeqAvg)
					print("\nMATMUL PAR INV Avg chronoTimes : ",chMMParAvg)
					print("\nLOT MATMUL SEQ INV Avg chronoTimes : ", chLMMSeqAvg)
					print("\nLOT MATMUL PAR INV Avg chronoTimes : ",chLMMParAvg)

				
				else:
					inv=0
					chMMSeq,minMMSeqT,maxMMSeqT=divideDatas(chronoTimes[0:part])
					chMMPar,minMMParT,maxMMParT=divideDatas(chronoTimes[part:(part*2)])
					chLMMSeq,minLMMSeqT,maxLMMSeqT=divideDatas(chronoTimes[(part*2):(part*3)])
					chLMMPar,minLMMParT,maxLMMParT=divideDatas(chronoTimes[(part*3):(part*4)])
					print("\nLOT MATMUL SEQ chronoTimes: ", chLMMSeq)
					print("\nLOT MATMUL PAR chronoTimes: ", chLMMPar)
					print("\nMATMUL SEQ chronoTimes: ", chMMSeq)
					print("\nMATMUL PAR chronoTimes: ", chMMPar)

					
					chMMSeqAvg = getAvgTimes(chMMSeq,minMMSeqT,maxMMSeqT)
					chMMParAvg = getAvgTimes(chMMPar,minMMParT,maxMMParT)
					chLMMSeqAvg = getAvgTimes(chLMMSeq,minLMMSeqT,maxLMMSeqT)
					chLMMParAvg = getAvgTimes(chLMMPar,minLMMParT,maxLMMParT)
					
					print("\nMATMUL SEQ Chrono AVG: ", chMMSeqAvg)
					print("\nMATMUL PAR Chrono AVG: ", chMMParAvg)
					print("\nLOT MATMUL SEQ Chrono AVG: ", chLMMSeqAvg)
					print("\nLOT MATMUL PAR Chrono AVG: ", chLMMParAvg)
					
				# sec -> millisec 
				chMMSeqAvg = chMMSeqAvg*1000
				chMMParAvg = chMMParAvg*1000
				chLMMSeqAvg = chLMMSeqAvg*1000
				chLMMParAvg = chLMMParAvg*1000
				#####SPEED UP#####
				speedUpMM=chMMSeqAvg/chMMParAvg
				speedUpLMM=chLMMSeqAvg/chLMMParAvg
				print("\nMATMUL Speedup: ", speedUpMM)
				print("\nLOT MATMUL Speedup: ", speedUpLMM)

			
			
			
			
			
			
				if inv==0:
					with open("./output/host_mat.csv",  "wb") as fcsv:
						writer = csv.writer(fcsv)
									
						writer.writerow(['MAT MUL','SEQ'])
						writer.writerows(chMMSeqAvg)
						writer.writerow(['MAT MUL','PAR'])
						writer.writerows(chMMParAvg)
						writer.writerow(['MAT MUL','SPEEDUP'])
						writer.writerows(speedUpMM)
						
						writer.writerow(['LOT MAT MUL','SEQ'])
						writer.writerows(chLMMSeqAvg)
						writer.writerow(['LOT MAT MUL','PAR'])
						writer.writerows(chLMMParAvg)
						writer.writerow(['LOT MAT MUL','SPEEDUP'])
						writer.writerows(speedUpLMM)
				else:
					with open("./output/host_mat_inv.csv",  "wb") as fcsv:
						writer = csv.writer(fcsv)
						writer.writerow(['INV MM','SEQ'])
						writer.writerows(chMMSeqAvg)
						writer.writerow(['INV MM','PAR'])
						writer.writerows(chMMParAvg)
						writer.writerow(['INV MM','SPEEDUP'])
						writer.writerows(speedUpMM)
						
						writer = csv.writer(fcsv)
						writer.writerow(['INV LOT MM','SEQ'])
						writer.writerows(chLMMSeqAvg)
						writer.writerow(['INV LOT MM','PAR'])
						writer.writerows(chLMMParAvg)
						writer.writerow(['INV LOT MM','SPEEDUP'])
						writer.writerows(speedUpLMM)
				
				
				
				
				for i in range(0,5):			
					plotCompTimeGraph(speedUpMM[i,:], speedUpMM[:,i],i,file[5:8],inv,1)
				for i in range(0,5):			
					plotCompTimeGraph(chMMParAvg[i,:], chMMParAvg[:,i],i,file[5:8],inv,0)
					
				for i in range(0,5):			
					plotCompTimeGraph(speedUpLMM[i,:], speedUpLMM[:,i],i,file[5:8],inv,1)
				for i in range(0,5):			
					plotCompTimeGraph(chLMMParAvg[i,:], chLMMParAvg[:,i],i,file[5:8],inv,0)
			
			elif file[5:8]=="cos":
			
			
			
			
			
				chAvg=np.zeros((5,5))
				half = len(chronoTimes)//2
		
				if file[-10:]=="invert.txt":
					inv=1
								
					chSeqAvg=divideDatasInv(chronoTimes[:half])
					chParAvg=divideDatasInv(chronoTimes[half:])
				
					print("\nSEQ INV Avg chronoTimes : ", chSeqAvg)
					print("\nPAR INV Avg chronoTimes : ", chParAvg)
				
				else:
					inv=0
					chSeq,minSeqT,maxSeqT=divideDatas(chronoTimes[:half])
					chPar,minParT,maxParT=divideDatas(chronoTimes[half:])
					print("\nSEQ chronoTimes: ", chSeq)
					print("\nPAR chronoTimes: ", chPar)
					
					chSeqAvg = getAvgTimes(chSeq,minSeqT,maxSeqT)
					chParAvg = getAvgTimes(chPar,minParT,maxParT)
		
					print("\nSEQ Chrono AVG: ", chSeqAvg)
					print("\nPAR Chrono AVG: ", chParAvg)
					
				# sec -> millisec	
				chSeqAvg = chSeqAvg*1000
				chParAvg = chParAvg*1000
				#####SPEED UP#####
				speedUp=chSeqAvg/chParAvg
				print("\nSpeedup: ", speedUp)
		
			
			
			
			
			
				if inv==0:	
					with open("./output/host_cos.csv",  "wb") as fcsv:
						writer = csv.writer(fcsv)
						writer.writerow(['COS','SEQ'])
						writer.writerows(chSeqAvg)
						writer.writerow(['COS','PAR'])
						writer.writerows(chParAvg)
						writer.writerow(['COS','SPEEDUP'])
						writer.writerows(speedUp)
				else:
					with open("./output/host_cos_inv.csv",  "wb") as fcsv:
						writer = csv.writer(fcsv)
						writer.writerow(['INV COS','SEQ'])
						writer.writerows(chSeqAvg)
						writer.writerow(['INV COS','PAR'])
						writer.writerows(chParAvg)
						writer.writerow(['INV COS','SPEEDUP'])
						writer.writerows(speedUp)
			
			
			
			#plotCompTimeGraph(speedUp[0,:], speedUp[:,0],0,file[5:8],inv,1)	
				for i in range(0,5):			
					plotCompTimeGraph(speedUp[i,:], speedUp[:,i],i,file[5:8],inv,1)
			
				#farei il grafico su comp time anche per inverted, mentre lo speed up solo per la versione normale, per adesso
				for i in range(0,5):			
					plotCompTimeGraph(chParAvg[i,:], chParAvg[:,i],i,file[5:8],inv,0)
			
								
				
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
	elif spUp==1:
		lbly="Speed Up"
		
	title=str(gType)
	title=title.upper()
	if inv==1:
		title+="-INVERTED"
	
		
	fig=plt.figure(num)

	ay = fig.add_subplot(111)
	ay.plot(x1, y1, '-', label = lblx1, linestyle='-',marker='o', color='black', linewidth=1)
	ay2 = ay.twiny()
	ay2.plot(x2, y2, '-r', label = lblx2, linestyle='-',marker='o', color='black', linewidth=3)	
	ay2.legend(loc="upper right")
	ay.legend(loc="lower right")
	ay.grid()
	
	ay.set_ylabel(lbly)
	ay.set_xlabel(lblx1)
	ay2.set_xlabel(lblx2)
	
	ay2.set_xticks(np.linspace(ay2.get_xticks()[0], ay2.get_xticks()[-1], len(ay.get_xticks())))
	
	plt.suptitle(title,  fontsize=16)
	plt.tight_layout()
	plt.show()
	
	#img_name='./plt_img/'+ gType+fname+str(plotId)
	#plt.savefig(img_name)
	#plotId+=1
	
	#figId+=1
	#plt.close(fig)


	
if __name__ == "__main__":
	main()









