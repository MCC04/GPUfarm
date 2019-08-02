#!/usr/bin/env python3
import matplotlib.pyplot as plt
import numpy as np
import math

#scalability=[]
#speedup=[]
#efficiency=[]
#ideal=[]
#workers=[]
#yTh=[]
#seqTime=0.0





ev_future1=[]
ev_future2=[]
ev_stream1=[]
ev_stream2=[]
ev_managed1=[]
ev_managed2=[]

def computeMeasures(str):
	global scalability
	global speedup
	global efficiency
	global ideal
	global workers
	global yTh
	global seqTime
	lines = open(str, 'r')
	chars = [line.rstrip('\n') for line in lines]

	Th=[]
	for line in chars:
		tokens= line.split(',', 4)
		if int(tokens[0]) not in workers:
			workers.append(int(tokens[0]))
		Th.append( (float(tokens[0]), float(tokens[2])) ) 
	
	temp=[]
	w=1.0
	for x,y in Th:
		if (w==x):	
			temp.append(y);
		else:
			print temp
			if(len(temp)>3):
				temp.remove(max(temp))
				temp.remove(min(temp))	
			yTh.append(sum(temp)/len(temp));	
			del temp[:]
			temp=[y]
			w*=2
	if(len(temp)>3):
		temp.remove(max(temp))
		temp.remove(min(temp))	
	yTh.append(sum(temp)/len(temp));	

	del temp[:]
	i=0
	for item in yTh:
		scalability.append(yTh[0]/item)
		speedup.append(seqTime/item)
		efficiency.append(speedup[i]/workers[i])
		ideal.append(seqTime/workers[i])
		i+=1
##########
###MAIN###
##########
def main():
		
	
	global ev_future1
	global ev_future2
	global ev_stream1
	global ev_stream2
	global ev_managed1
	global ev_managed2	
	
	elem_num=[7168, 14336, 28672]
	#####FUTURE
	evf11=[5.876,5.84381,3.53504,2.98032]
	evf12=[5.0959,5.07344,5.07715,5.06794, 5.09056,5.09018,5.08838,5.10032]
	evf13=[8.19578,8.15603,8.24342,8.15798, 8.12784,8.19821,8.15738,8.27238, 8.21318,8.2079,8.23363,8.2256,8.2343,8.18224,8.17744,8.18509]
	
	evf21=[9.93408,9.89862,9.90614,9.91248]
	evf22=[10.0837,10.0563,10.0782,10.0604,10.0911,10.0655,10.0663,10.0739]
	evf23=[16.0673,16.0424,16.1232,16.1083,16.059,16.0925,16.0151,16.1343,16.2135,18.205,18.7453,12.2501,9.3879,8.61568,8.188, 7.03098]
		
	ev_future1=[sum(evf11)/len(evf11), sum(evf12)/len(evf12), sum(evf13)/len(evf13) ]		    
	ev_future2=[sum(evf21)/len(evf21), sum(evf22)/len(evf22), sum(evf23)/len(evf23)]
	
	#####STREAM
	evs11=[23.2502,11.8392,10.9233,9.91619]
	evs12=[40.0063,43.5936,30.3528,19.01,13.8535,11.9047,11.3306,10.0744]
	evs13=[63.6128,29.3755,21.8169,20.1476,20.1484, 20.174,20.1659,20.0602,19.9698,19.9751,19.9187,19.3331,18.279,18.2704,18.2181,18.2244 ]
	
	evs21=[39.7914,40.6276,46.1913,25.9477]
	evs22=[79.6044,63.6733,29.2646,21.7612,19.9162, 19.9308,19.9318,19.9452]
	evs23=[147.159,51.5029,39.8448,39.8699,39.5747,39.404, 37.4573,36.0798,36.0922,36.0433,36.0318,36.0203,36.0301,35.9394,35.7063,35.7174]
	ev_stream1=[sum(evs11)/len(evs11), sum(evs12)/len(evs12), sum(evs13)/len(evs13) ]		    
	ev_stream2=[sum(evs21)/len(evs21), sum(evs22)/len(evs22), sum(evs23)/len(evs23)]
	
	#####MANAGED	 
	evm11=[20.1722,19.9623,20.4939,23.0458]
	evm12=[40.5075,45.215,34.4367,19.7124,14.1096, 12.2516,11.1441,10.3775]
	evm13=[84.6904,46.2082,26.0967,21.8732,20.2462, 20.3298,19.9057,19.8666,19.7955,19.7259,19.5743,19.6213,19.6112, 18.7116,18.4721,18.5874]
	  
	evm21=[40.8991,46.3095,26.4781,18.2027]
	evm22=[82.9185,51.2645,25.6922,21.2253,19.9641, 19.1913,19.3029,19.3244]
	evm23=[128.711,45.8425,38.9774,38.2694,38.043, 37.3479,37.2321,36.2673,36.2581,36.2161,35.9637,35.9479,35.9676, 35.8836,35.9276,35.9569]
	ev_managed1=[sum(evm11)/len(evm11), sum(evm12)/len(evm12), sum(evm13)/len(evm13)]
		    
	ev_managed2=[sum(evm21)/len(evm21), sum(evm22)/len(evm22), sum(evm23)/len(evm23)]




	#PROFILER VALUES
	
	
	
	
	
	##########
	#SEQUENTIAL
	##########
	#if n==1:
		#linesSeq = open('./results/gen_seq1.txt', 'r')
	#elif n==2:
		#linesSeq = open('./results/gen_seq2.txt', 'r')
	#elif n==3:
		#linesSeq = open('./results/gen_seq3.txt', 'r')
	#charsSeq = [line.rstrip('\n') for line in linesSeq]

	#temp=[]
	#seq=[]
	#allComps=[]
	#for line in charsSeq:
		#tokens= line.split(', ',3)
		#print tokens
		#allComps.append(float(tokens[1])) #comp Time

	#print("\nallComps: ")
	#print(allComps)

	#allComps.remove(max(allComps))
	#allComps.remove(min(allComps))
	#seqTime=sum(allComps)/len(allComps)

	#print("\nseq: ")
	#print(seqTime)

	
	

	######################
	########GRAPHS########
	######################	
	#FUTURE COMPARISON
	plt.figure(1)
	plt.plot(elem_num, ev_future1, marker='.',label='Future 500')
	plt.plot(elem_num, ev_future2, marker='.',label='Future 1000')
	#plt.plot(workers, nideal ,linestyle='--',label='Ideal Comp Time')
	#plt.plot(np.arange(0, max(workers)+1, 1), [seqTime]*(max(workers)+1), label='sequential')
	plt.xlabel('ELEM NUMBER')
	plt.ylabel('EVENT ELAPSED (ms)')
	plt.xticks(elem_num)
	#plt.ylim((-1.0, 20.0))
	#plt.xlim((0, max(workers)+1))
	#plt.yticks(np.arange(-0.5, 20.0, 5.0))
	#plt.xticks(np.arange(0.0, float(max(workers)), 20))
	plt.legend()
	plt.grid()
	plt.show()
	
	#STREAM COMPARISON
	plt.figure(2)
	plt.plot(elem_num, ev_stream1, marker='.',label='Stream 500')
	plt.plot(elem_num, ev_stream2, marker='.',label='Stream 1000')
	#plt.plot(workers, nideal ,linestyle='--',label='Ideal Comp Time')
	#plt.plot(np.arange(0, max(workers)+1, 1), [seqTime]*(max(workers)+1), label='sequential')
	plt.xlabel('ELEM NUMBER')
	plt.ylabel('EVENT ELAPSED (ms)')
	plt.xticks(elem_num)
	#plt.ylim((-1.0, 20.0))
	#plt.xlim((0, max(workers)+1))
	#plt.yticks(np.arange(-0.5, 20.0, 5.0))
	#plt.xticks(np.arange(0.0, float(max(workers)), 20))
	plt.legend()
	plt.grid()
	plt.show()
	
	#STREAM COMPARISON
	plt.figure(3)
	plt.plot(elem_num, ev_managed1, marker='.',label='Managed 500')
	plt.plot(elem_num, ev_managed2, marker='.',label='Managed 1000')
	#plt.plot(workers, nideal ,linestyle='--',label='Ideal Comp Time')
	#plt.plot(np.arange(0, max(workers)+1, 1), [seqTime]*(max(workers)+1), label='sequential')
	plt.xlabel('ELEM NUMBER')
	plt.ylabel('EVENT ELAPSED (ms)')
	plt.xticks(elem_num)
	#plt.ylim((-1.0, 20.0))
	#plt.xlim((0, max(workers)+1))
	#plt.yticks(np.arange(-0.5, 20.0, 5.0))
	#plt.xticks(np.arange(0.0, float(max(workers)), 20))
	plt.legend()
	plt.grid()
	plt.show()
	
	#500 ITERATIONS COMPARISON
	plt.figure(4)
	plt.plot(elem_num, ev_future1, marker='.',label='Future 500')
	plt.plot(elem_num, ev_stream1, marker='.',label='Stream 500')
	plt.plot(elem_num, ev_managed1, marker='.',label='Managed 500')
	#plt.plot(workers, nideal ,linestyle='--',label='Ideal Comp Time')
	#plt.plot(np.arange(0, max(workers)+1, 1), [seqTime]*(max(workers)+1), label='sequential')
	plt.xlabel('ELEM NUMBER')
	plt.ylabel('EVENT ELAPSED (ms)')
	plt.xticks(elem_num)
	#plt.ylim((-1.0, 20.0))
	#plt.xlim((0, max(workers)+1))
	#plt.yticks(np.arange(-0.5, 20.0, 5.0))
	#plt.xticks(np.arange(0.0, float(max(workers)), 20))
	plt.legend()
	plt.grid()
	plt.show()
	
	#1000 ITERATIONS COMPARISON
	plt.figure(5)
	plt.plot(elem_num, ev_future2, marker='.',label='Future 1000')
	plt.plot(elem_num, ev_stream2, marker='.',label='Stream 1000')
	plt.plot(elem_num, ev_managed2, marker='.',label='Managed 1000')
	#plt.plot(workers, nideal ,linestyle='--',label='Ideal Comp Time')
	#plt.plot(np.arange(0, max(workers)+1, 1), [seqTime]*(max(workers)+1), label='sequential')
	plt.xlabel('ELEM NUMBER')
	plt.ylabel('EVENT ELAPSED (ms)')
	plt.xticks(elem_num)
	#plt.ylim((-1.0, 20.0))
	#plt.xlim((0, max(workers)+1))
	#plt.yticks(np.arange(-0.5, 20.0, 5.0))
	#plt.xticks(np.arange(0.0, float(max(workers)), 20))
	plt.legend()
	plt.grid()
	plt.show()
	
	plt.figure(6)
	plt.plot(elem_num, ev_future1,linestyle='--', marker='.',label='Future 500')
	plt.plot(elem_num, ev_stream1,linestyle='--', marker='.',label='Stream 500')
	plt.plot(elem_num, ev_managed1,linestyle='--', marker='.',label='Managed 500')
	plt.plot(elem_num, ev_future2, marker='.',label='Future 1000')
	plt.plot(elem_num, ev_stream2, marker='.',label='Stream 1000')
	plt.plot(elem_num, ev_managed2, marker='.',label='Managed 1000')
	#plt.plot(workers, nideal ,linestyle='--',label='Ideal Comp Time')
	#plt.plot(np.arange(0, max(workers)+1, 1), [seqTime]*(max(workers)+1), label='sequential')
	plt.xlabel('ELEM NUMBER')
	plt.ylabel('EVENT ELAPSED (ms)')
	#plt.ylim((-1.0, 20.0))
	#plt.xlim((0, max(workers)+1))
	#plt.yticks(np.arange(-0.5, 20.0, 5.0))
	plt.xticks(elem_num)
	plt.legend()
	plt.grid()
	plt.show()
	
	
	
	
	
		
	#SCALABILITY
	#plt.figure(2)
	#plt.plot(ntwks, nscalability, marker='.',label='New Thread')
	#plt.plot(ffwks, ffscalability, marker='.', label='FastFlow')
	#plt.plot(workers, workers,linestyle='--', label='Ideal Scalability')
	#plt.xlabel('PARALLELISM DEGREE')
	#plt.ylabel('SCALABILITY')
	#plt.ylim((-1.0, float(max(workers))))
	#plt.xlim((-1.0, max(workers)+1))
	#plt.xticks(np.arange(0.0, float(max(workers)), 20))
	#plt.legend()
	#plt.grid()
	#plt.show()

	
	


if __name__ == "__main__":
	main()









