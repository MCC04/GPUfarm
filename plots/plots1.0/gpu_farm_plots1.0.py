#!/usr/bin/env python3
import matplotlib.pyplot as plt
import numpy as np
import math
import csv

	
def getDatas(str):
	linesSeq = open(str, 'r')	
	charsSeq = [line.rstrip('\n') for line in linesSeq]
	
	tokens=[]
	evTimes=[]
	for line in charsSeq:
		#print line
		if line[:1]=='*':
			tokens= line.split(',',6)
			#print tokens
			if str[-9:]=="oneSm.txt":
				evTimes.append(float(tokens[3]))
			else:
				evTimes.append(float(tokens[4])) #Time measured by events

	
	print(evTimes)

	return evTimes
	
def getAvgTimes(times1, times2):
	l1=[sum(times1[0:3])/4, sum(times1[4:11])/8, sum(times1[12:27])/16 ]
	l2=[sum(times2[0:3])/4, sum(times2[4:11])/8, sum(times2[12:27])/16 ]
	
	return l1,l2
	
##########
###MAIN###
##########
def main():

	elem_num=[7168, 14336, 28672]	

	print("\nStream 500 Times: ")
	stream1 = getDatas('../results/stream_m1.txt')
	print("\nStream 1000 Times: ")
	stream2 = getDatas('../results/stream_m2.txt')

	print("\nFuture 500 Times: ")
	future1 = getDatas('../results/future_m1.txt')
	print("\nFuture 1000 Times: ")
	future2 = getDatas('../results/future_m2.txt')
	
	print("\nManaged 500 Times: ")
	managed1 = getDatas('../results/managed_m1.txt')
	print("\nManaged 1000 Times: ")
	managed2 = getDatas('../results/managed_m2.txt')

	print("\nOne SM 1000 Times: ")
	oneSm = getDatas('../results/oneSm.txt')

	s1, s2 = getAvgTimes(stream1, stream2)
	f1, f2 = getAvgTimes(future1, future2)
	m1, m2 = getAvgTimes(managed1, managed2)		
	one=l2=[sum(oneSm[0:3])/4, sum(oneSm[4:11])/8, sum(oneSm[12:27])/16 ]
	print("\nFuture 500 avg: ")
	print(f1)	
	print("\nFuture 1000 avg: ")
	print(f2)	
	print("\nStream 500 avg: ")
	print(s1)
	print("\nStream 1000 avg: ")
	print(s2)
	print("\nManaged 500 avg: ")
	print(m1)
	print("\nManaged 1000 avg: ")
	print(m2)
	print("\nOne SM 1000 avg: ")
	print(one)	
	
	o=np.array(one, dtype=np.float)
	s=np.array(s1, dtype=np.float)
	f=np.array(f1, dtype=np.float)
	m=np.array(m1, dtype=np.float)
	
	speedUp1 = o/f
	speedUp2 = o/s
	speedUp3 = o/m	
	print("\nFuture speedup: ")
	print(speedUp1)	
	print("\nStream speedup: ")
	print(speedUp2)
	print("\nManaged Memory Stream speedup: ")
	print(speedUp3)
	

	######################
	########GRAPHS########
	######################	
	#500 ITERATIONS COMPARISON
	plt.figure(1)
	plt.plot(elem_num, f1, marker='.',label='Future 500')
	plt.plot(elem_num, s1, marker='.',label='Stream 500')
	plt.plot(elem_num, m1, marker='.',label='Managed 500')
	plt.xlabel('ELEM NUMBER')
	plt.ylabel('EVENT ELAPSED (ms)')
	plt.xticks(elem_num)
	plt.legend()
	plt.grid()
	plt.show()
	
	#COMPARISON WITH ONE_SM
	plt.figure(2)
	plt.plot(elem_num, f1, marker='.',label='Future 500')
	plt.plot(elem_num, s1, marker='.',label='Stream 500')
	plt.plot(elem_num, m1, marker='.',label='Managed 500')
	plt.plot(elem_num, one, marker='.',label='One SM 500')
	plt.xlabel('ELEM NUMBER')
	plt.ylabel('EVENT ELAPSED (ms)')
	plt.xticks(elem_num)
	plt.legend()
	plt.grid()
	plt.show()
	
	#1000 ITERATIONS COMPARISON
	plt.figure(3)
	plt.plot(elem_num, f2, marker='.',label='Future 1000')
	plt.plot(elem_num, s2, marker='.',label='Stream 1000')
	plt.plot(elem_num, m2, marker='.',label='Managed 1000')
	plt.xlabel('ELEM NUMBER')
	plt.ylabel('EVENT ELAPSED (ms)')
	plt.xticks(elem_num)
	plt.legend()
	plt.grid()
	plt.show()
	
	#GLOBAL COMPARISON
	plt.figure(4)
	plt.plot(elem_num, f1,linestyle='--', marker='.',label='Future 500')
	plt.plot(elem_num, s1,linestyle='--', marker='.',label='Stream 500')
	plt.plot(elem_num, m1,linestyle='--', marker='.',label='Managed 500')
	#plt.plot(elem_num, one,linestyle=':', marker='.',label='One SM 500')
	plt.plot(elem_num, f2, marker='.',label='Future 1000')
	plt.plot(elem_num, s2, marker='.',label='Stream 1000')
	plt.plot(elem_num, m2, marker='.',label='Managed 1000')
	plt.xlabel('ELEM NUMBER')
	plt.ylabel('EVENT ELAPSED (ms)')
	plt.xticks(elem_num)
	plt.legend()
	plt.grid()
	plt.show()
	
	#SPEEDUP
	plt.figure(5)
	plt.plot(elem_num, speedUp1, marker='.',label='Future speed up')
	plt.plot(elem_num, speedUp2, marker='.',label='Stream speed up')
	plt.plot(elem_num, speedUp3, marker='.',label='Managed speed up')
	plt.plot(elem_num, elem_num,linestyle='--', marker='.',label='Ideal speed up')
	plt.xlabel('ELEM NUMBER')
	plt.ylabel('SPEEDUP')
	plt.xticks(elem_num)
	plt.legend()
	plt.grid()
	plt.show()
	


if __name__ == "__main__":
	main()









