#!/usr/bin/env python3
# coding=utf-8

#import glob
import os
import matplotlib.pyplot as plt
import numpy as np
import math
import csv



testNum=10
singleResSize = testNum*5*5	

def getDatas(str):
	linesSeq = open(str, 'r')	
	charsSeq = [line.rstrip('\n') for line in linesSeq]
	
	inputParams=[]
	tokens=[]
	lbls=[]
	evTimes=[]
	chronoTimes=[]

	for line in charsSeq:
		tokens= line.split(',',10)
		lbls.append(tokens[0])
		evTimes.append(float(tokens[1]))
		chronoTimes.append(float(tokens[2]))			
		
		if(len(tokens)>2):
			inputParams.append([int(x) for x in tokens[3:]])

	print("\nInput params: ",inputParams)
	print("\nEvent times: ",evTimes)
	print("\nChrono times: ",chronoTimes)
	print("\nLabels: ",lbls)


	return lbls,inputParams, evTimes, chronoTimes


##########
###MAIN###
##########
def main():
	testNum=10
	paramNum=5
	for file in os.listdir("../results/"):
	    if file.endswith(".txt"):
		print(os.path.join("../results/", file))		
	
		
		if file[0:13]=="dev_sp_stream":# and file[4:9]!="lowpar":	
			if file[-7:-4]=="inv":
				f=os.path.join("../results/", file)
				lbls,inputs,evTimes,chronoTimes = getDatas(f)
			
				csvPath="./output/dev_spup"
		
				print("\nEv len: ",len(evTimes))
				print("\nchrono len: ",len(chronoTimes))					
				print("\ninputs len: ",len(inputs))
		
				chFinalAvgs=np.zeros((5,5))
				evFinalAvgs=np.zeros((5,5))

				chLowFinalAvgs=np.zeros((5,5))
				evLowFinalAvgs=np.zeros((5,5))
			
				tmpChFinalAvgs=np.zeros((5,5))
				tmpEvFinalAvgs=np.zeros((5,5))

			
				evAvg = []
				chAvg = []	
				xRow = [] #COS=N_size; MAT=matN	
				xCol = [] #COS=M_iter; MAT=Ndim
				lbltmp = lbls[0]
				i = 0
				low = 0

				for l in lbls:
					print("***LLL", l, i)
					if l==lbltmp and i < len(lbls)-1:
						evAvg.append(evTimes[i])
						chAvg.append(chronoTimes[i])
					
					else:
						lbltmp = l
						print("***LBL", lbltmp)
						k = 0
						m = 0				
						t = 0
						while t<len(evAvg):
						
							evChunk = evAvg[t:(t+testNum)]
							chChunk = chAvg[t:(t+testNum)]
						
							print("***XCOLS   ", xCol)
							print("***XROWS   ", xRow)
						
							tmpEvFinalAvgs[m][k], tmpChFinalAvgs[m][k]=getChunkAvg(evChunk,chChunk)
						
							#print("***k", k)
							#print("***m", m)	
						
						
							#print("***MAT CH \n", tmpChFinalAvgs)
							#print("***MAT EV \n", tmpEvFinalAvgs)
					
							#print("***IN LEN   ", len(inputs))
						
						
							k+=1
						
				
					
							if(k>=5):
								#print("***inputs dim : ", len(inputs[0]), len(inputs[1]))
							
								m+=1
								k=0
								#print("***MMMM : ", m)
								if(m>=5):
									m=0
									break
	
								#xRow.append(inputs[m*t][2]) #1=N_size;2=M_iter
								#xRow.append(inputs[m*t][1]) 
						
							#xCol.append(inputs[k*t][1])
							#xCol.append(inputs[k*t][0])#0=dim;1=matN
							
							t+=testNum
						
						
						
					
						if(low):
							print("***LOW : ", low)
							chLowFinalAvgs=tmpChFinalAvgs
							evLowFinalAvgs=tmpEvFinalAvgs
						
							#if I'm here it means I can plot a speedup, since 
							#I've both high and low measures of some test
							speedUp = evLowFinalAvgs/evFinalAvgs
							print("***SPEEDUP: \n", speedUp)
							print("***LBL", lbltmp)
							csvPath+=lbltmp
							csvPath+=".csv"
							#xRow =[32,64,128,256,512]			
							#xCol=[56,112,168,224,280]							
										
							xCol=[64,128,256,512,1024]
							xRow =[114688,229376,458752,917504,1835008]
							
							writeToCSV(csvPath, lbltmp, chFinalAvgs, evFinalAvgs, evLowFinalAvgs, speedUp)
							doPlots(evFinalAvgs, evLowFinalAvgs, speedUp, xRow, xCol, lbltmp)
										
							xCol=[]
							xRow =[]
							low=0
						else:
							print("***LOW : ", low)
							chFinalAvgs=tmpChFinalAvgs
							evFinalAvgs=tmpEvFinalAvgs
							low=1
						
						tmpChFinalAvgs = np.zeros((5,5))
						tmpEvFinalAvgs = np.zeros((5,5))
					

						
						
						
						
						
						
						
						
							
						evAvg=[]
						chAvg=[]
						#evAvg.append(evTimes[i])
						#chAvg.append(chronoTimes[i])
						
							
					
					i+=1

			#else:
			#	for l in lbls:
			#		print("***LLL", l, i)
			#		if l==lbltmp and i < len(lbls)-1:
			#			evAvg.append(evTimes[i])
			#			chAvg.append(chronoTimes[i])
					
			#		else:
			#			ch,minC,maxC = divideDatas(chAvg)
			#			ev,minE,maxE = divideDatas(evAvg)
		
###############
### GET AVG ###
###############	
		
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
				
				
###############
### GET AVG ###
###############
def getChunkAvg(evT,chT):		
	print("***evChunk \n", evT)
	print("***chChunk \n", chT)

	j=0
	for j in range(2):							
		evT.remove(min(evT))
		chT.remove(min(chT))
		evT.remove(max(evT))
		chT.remove(max(chT))


	ch = sum(chT[:])/len(chT)
	ev = sum(evT[:])/len(evT)
	
	return ev,ch

			
#############
#WRITE TO CSV
#############			
def writeToCSV(csvPath, label, chronoTimes, eventTimes, eventLowTimes, speedUp):

	with open(csvPath,  "wb") as fcsv:
		writer = csv.writer(fcsv)   
	    
	    
	    	#write event	    
		writer.writerow([label,'LOW PAR'])
		writer.writerows(eventLowTimes)

		writer.writerow([label,'AVG'])
		writer.writerows(eventTimes)

		writer.writerow([label,'SPEEDUP'])
		writer.writerows(speedUp)	

		#write chrono 
    		writer.writerow([label,'CHRONO MEASURES'])
		writer.writerows(chronoTimes)
		
	    
			
			
			
			
########################
##### PLOTS ON COS #####
########################
def doPlots(evTimes, evLowTimes, speedUp, xRows, xCols, lbl):				
	#for i in range(0,5):			
	#	plotCompTimeGraph(evTimes[i,:], evLowTimes[:,i], xRows, lbl)
	#	plotCompTimeGraph(evTimes[:,i], evLowTimes[i,:], xCols, lbl)

	for i in range(0,5):			
		plotSpeedup(speedUp[i,:], xRows, i,0, lbl)
		plotSpeedup(speedUp[:,i], xCols, i,0, lbl)





				
plotId=0
figId=0
	
def plotCompTimeGraph(y1, y2, x1, lblMeasures):

	global plotId	
	global figId		

	#if gType=="mat":
	#	x1=(4,16,32,64,128) #nMat
	#	x2=(32,64,128,256,512) #dimMat			
#		lblx1="N mat"
#		lblx2="DIM mat"
#	elif gType=="cos":
#		x1=(10,50,250,1250,2500)
#		x2=(3584,7168,14336,28672,57344)
#		lblx1="M"
#		lblx2="N"
		
#	if spUp==0:
#		lbly="Comp Time (ms)" + lblMeasure
#		fname= 'comp'
#	elif spUp==1:
#		lbly="Speed Up" + lblMeasure
#		fname = 'spup'
		
	title=str(lblMeasures)
	title=title.upper()
	#if inv==1:
	#	title+="-INVERTED"
	#	fname+='_inv'

	fig=plt.figure(figId)

	ay = fig.add_subplot(111)
	ay.plot(x1, y1, '-', label = lblx1, marker='o', linestyle='-', color='black', linewidth=1)

	ay2 = ay.twiny()
	ay2.plot(x1, y2, '-r', label = lblx2, marker='o', linestyle='-', color='black', linewidth=3)	
	ay2.legend(loc="upper right")
	ay.legend(loc="lower right")
	ay.grid()
	
	ay.set_ylabel(lbly)
	ay.set_xlabel(lblx1)	
	ay2.set_xlabel(lblx2)

	
	ay2.set_xticks(np.linspace(ay2.get_xticks()[0], ay2.get_xticks()[-1], len(ay.get_xticks())))

	plt.suptitle(title,  fontsize=16,horizontalalignment='left')
	plt.tight_layout()
	plt.show()	
	
	#img_name='./plt_img/'+ str(plotId)
	#plt.savefig(img_name)
	plotId+=1
	
	figId+=1
	#plt.close(fig)
	
	
def plotSpeedup(y1, x1, num, inv,lblMeasures):			

	global plotId
	global figId

	lbly="Speed Up" + lblMeasures		
	title=str(lbly)
	title=title.upper()
	
	if inv==1:
		title+="-INVERTED"

	plt.figure(figId)

	plt.plot(x1, y1, '-', label = 'Speedup', marker='o', linestyle='-', color='black', linewidth=1)
	plt.plot(x1, x1, marker='.',label='Ideal speed up',color='black',linestyle='--')
	
	#plt.xlabel(lblx1)
	plt.ylabel(lbly)		
	plt.legend(loc="upper right")

	#plt.suptitle(title,  fontsize=16, horizontalalignment='left')
	#plt.tight_layout()	

	#img_name='./plt_img/spup'+str(plotId)
	#plt.savefig(img_name)
	plt.show()
	plotId+=1
	figId+=1
	#plt.close()
	
	
	
if __name__ == "__main__":
	main()


