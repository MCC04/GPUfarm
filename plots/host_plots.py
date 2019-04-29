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
			if(len(tokens)>1):
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
			print(k)
			temp.append(c)
			k+=1
			
		#elif k>=testNum or count>=len(chrono):
		else:
			k=0
			temp.remove(max(temp))
			temp.remove(min(temp))
			print("i: ",i,"j: ",j)
			print("temp: ",temp)
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
		
	
		
	

	#for f in files:
		#print("\n***** Datas of ***** ")
		#print(f)
			
		
		if file[0:4]=="host": # or str[-22:]=="host_cosMat_invert.txt":	
			f=os.path.join("../results/", file)
			inputs,chronoTimes = getDatas(f)
			
			
			
			print("\nchrono len: ")
			print(len(chronoTimes))
			
			print("\ninputs len: ")
			print(len(inputs))
			
			
			chAvg=np.zeros((5,5))
			half = len(chronoTimes)//2
		
			if file[-10:]=="invert.txt":
				inv=1
				#chVectAvg=getAvgTimesInv(chronoTimes)
				
				#print(half)
				#print(chronoTimes[:half])
				#print(chronoTimes[half:])
				
				chSeqAvg=divideDatasInv(chronoTimes[:half])
				chParAvg=divideDatasInv(chronoTimes[half:])
				
				#divideDatasInv(chronoTimes)
				#chronoTimes.append(float(tokens[0]))
				print("\nSEQ INV Avg chronoTimes : ")
				print(chSeqAvg)
				print("\nPAR INV Avg chronoTimes : ")
				print(chParAvg)
				
				#chAvg = divideDatasInv(chVectAvg)
			else:
				inv=0
				chSeq,minSeqT,maxSeqT=divideDatas(chronoTimes[:half])
				chPar,minParT,maxParT=divideDatas(chronoTimes[half:])
				print("\nSEQ chronoTimes: ")
				print(chSeq)
				#print("\nMin Times: ")
				#print(minSeqT)
				#print("\nMax Times: ")
				#print(maxSeqT)
				
				print("\nPAR chronoTimes: ")
				print(chPar)
				#print("\nMin Times: ")
				#print(minParT)
				#print("\nMax Times: ")
				#print(maxParT)
				
				chSeqAvg = getAvgTimes(chSeq,minSeqT,maxSeqT)
				chParAvg = getAvgTimes(chPar,minParT,maxParT)
				#evTimes.append(float(tokens[0]))
				#chronoTimes.append(float(tokens[1]))
				
		
			
		
				print("\nSEQ Chrono AVG: ")
				print(chSeqAvg)
			
				print("\nPAR Chrono AVG: ")
				print(chParAvg)
		

				

	
	#print("\nStream Times: ")
	#stream1 = getDatas('../results/stream.txt')


	#print("\nFuture Times: ")
	#future1 = getDatas('../results/future.txt')

	
	#print("\nManaged Times: ")
	#managed1 = getDatas('../results/managed.txt')


	#print("\nOne SM Times: ")
	#oneSm = getDatas('../results/oneSm.txt')

	#elems=[1792,3584,7168,14336,28672,57344]
	#iterNum=[10,50,250,1250,2500]


	#s1 = getAvgTimes2(stream1)
	#f1 = getAvgTimes2(future1)
	#m1 = getAvgTimes2(managed1)	
	#one = getAvgTimes2(oneSm)	
	
	#one=l2=[sum(oneSm[0:3])/4, sum(oneSm[4:11])/8, sum(oneSm[12:27])/16 ]
	#print("\nFuture avg: ")
	#print(f1)	
	
	#print("\nStream avg: ")
	#print(s1)
	
	#print("\nManaged avg: ")
	#print(m1)

	#print("\nOne SM avg: ")
	#print(one)	
	
	
	
	
	#####SPEED UP#####
	#o=np.array(one, dtype=np.float)
	#s=np.array(s1, dtype=np.float)
	#f=np.array(f1, dtype=np.float)
	#m=np.array(m1, dtype=np.float)
				
	
			speedUp=chSeqAvg/chParAvg
			print("\nSpeedup: ")
			print(speedUp)
			#break
			
			
			
			
			
			if file[5:8]=="mat":
			
			    	#writeToCsv()	    
				if inv==0:
					with open("./output/host_mat.csv",  "wb") as fcsv:
						writer = csv.writer(fcsv)
									
						writer.writerow(['MAT MUL','SEQ'])
						writer.writerows(chSeqAvg)
						writer.writerow(['MAT MUL','PAR'])
						writer.writerows(chParAvg)
						writer.writerow(['MAT MUL','SPEEDUP'])
						writer.writerows(speedUp)
				else:
					with open("./output/host_mat_inv.csv",  "wb") as fcsv:
						writer = csv.writer(fcsv)
						writer.writerow(['INV MM','SEQ'])
						writer.writerows(chSeqAvg)
						writer.writerow(['INV MM','PAR'])
						writer.writerows(chParAvg)
						writer.writerow(['INV MM','SPEEDUP'])
						writer.writerows(speedUp)
			
			elif file[5:8]=="cos":
				#with open("./output/host_cos.csv",  "wb") as fcsv:
					#writer = csv.writer(fcsv)
				    	#writeToCsv()	    

				if inv==0:	
					with open("./output/host_cos.csv",  "wb") as fcsv:
						writer = csv.writer(fcsv)
					    	#writeToCsv()					
						writer.writerow(['COS','SEQ'])
						writer.writerows(chSeqAvg)
						writer.writerow(['COS','PAR'])
						writer.writerows(chParAvg)
						writer.writerow(['COS','SPEEDUP'])
						writer.writerows(speedUp)
				else:
					with open("./output/host_cos_inv.csv",  "wb") as fcsv:
						writer = csv.writer(fcsv)
					    	#writeToCsv()	
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
			
				
				
			#if file[5:8]=="mat":
				#nMat=(4,16,32,64,128)
				#dimMat=(32,64,128,256,512)
				
				#fig=plt.figure(1)
	
				#ay = fig.add_subplot(111)
	
				#ay.plot(nMat, chParAvg[0,:], '-', label = 'Nmat')
				#ay.legend(loc=1)
				#ay.plot(time, Rn, '-', label = 'Rn')
				#ay2 = ay.twiny()
				#ay2.plot(dimMat, chParAvg[:,0], '-r', label = 'dimMat')
				#ay2.legend(loc=0)
				#ay.grid()
				#ay.set_xlabel("N mat")
				#ay.set_ylabel("Comp Time (ms)")
				#ay2.set_ylabel("DIM mat")
				#ay2.set_ylim(0, 35)
				#ay.set_ylim(-20,100)
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

	ay.plot(x1, y1, '-', label = lblx1, linestyle='-', color='black', linewidth=1)
	
		
	
	#ay.set_yticks(y1)
	
	#ay.plot(time, Rn, '-', label = 'Rn')
	#plt.ylim(y1[0], y1[-1])
	ay2 = ay.twiny()
	
	
	
	if spUp==1:
		ay.plot(x1, x1, label = 'ideal', linestyle=':', color='black')
		ay.set_ylim(y1[0], y1[-1]*20)
		#ay.set_yticks(y1)
		#ay2.set_ylim(y2[0], y2[-1])
		#ay2.set_yticks(y2)
	ay2.plot(x2, y2, '-r', label = lblx2, linestyle='-', color='black', linewidth=3)	
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



	
if __name__ == "__main__":
	main()









