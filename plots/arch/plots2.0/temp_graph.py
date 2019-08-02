#ITERATIONS COMPARISON
	plt.figure(1)
	
	iterAvg1 = (f1[0]+f1[5]+f1[10]+f1[15]+f1[20]+f1[25])/5 
	iterAvg2 = (f1[1]+f1[6]+f1[11]+f1[16]+f1[21]+f1[26])/5
	iterAvg3 = (f1[2]+f1[7]+f1[12]+f1[17]+f1[22]+f1[27])/5
	iterAvg4 = (f1[3]+f1[8]+f1[13]+f1[18]+f1[23]+f1[28])/5
	iterAvg5 = (f1[4]+f1[9]+f1[14]+f1[19]+f1[24]+f1[29])/5
	print iterAvg1
	plt.plot(iterNum, [iterAvg1,iterAvg2,iterAvg3,iterAvg4,iterAvg5], marker='.',label='Future')
	
	iterAvg1 = (s1[0]+s1[5]+s1[10]+s1[15]+s1[20]+s1[25])/5 
	iterAvg2 = (s1[1]+s1[6]+s1[11]+s1[16]+s1[21]+s1[26])/5
	iterAvg3 = (s1[2]+s1[7]+s1[12]+s1[17]+s1[22]+s1[27])/5
	iterAvg4 = (s1[3]+s1[8]+s1[13]+s1[18]+s1[23]+s1[28])/5
	iterAvg5 = (s1[4]+s1[9]+s1[14]+s1[19]+s1[24]+s1[29])/5
	plt.plot(iterNum, [iterAvg1,iterAvg2,iterAvg3,iterAvg4,iterAvg5], marker='.',label='Stream')
	
	iterAvg1 = (m1[0]+m1[5]+m1[10]+m1[15]+m1[20]+m1[25])/5 
	iterAvg2 = (m1[1]+m1[6]+m1[11]+m1[16]+m1[21]+m1[26])/5
	iterAvg3 = (m1[2]+m1[7]+m1[12]+m1[17]+m1[22]+m1[27])/5
	iterAvg4 = (m1[3]+m1[8]+m1[13]+m1[18]+m1[23]+m1[28])/5
	iterAvg5 = (m1[4]+m1[9]+m1[14]+m1[19]+m1[24]+m1[29])/5
	plt.plot(iterNum, [iterAvg1,iterAvg2,iterAvg3,iterAvg4,iterAvg5], marker='.',label='Managed')
	plt.xlabel('KERNEL ITERATION NUMBER')
	plt.ylabel('EVENT ELAPSED (ms)')
	plt.xticks(iterNum)
	plt.legend()
	plt.grid()
	plt.show()
	
	#ELEM NUM COMPARISON
	plt.figure(2)
	iterAvg1 = sum(f1[0:4])/6 
	iterAvg2 = sum(f1[5:9])/6 
	iterAvg3 = sum(f1[10:14])/6 
	iterAvg4 = sum(f1[15:19])/6 
	iterAvg5 = sum(f1[20:24])/6
	iterAvg6 = sum(f1[25:29])/6
	plt.plot(elems, [iterAvg1,iterAvg2,iterAvg3,iterAvg4,iterAvg5,iterAvg6], marker='.',label='Future')
	
	iterAvg1 = sum(s1[0:4])/6 
	iterAvg2 = sum(s1[5:9])/6 
	iterAvg3 = sum(s1[10:14])/6 
	iterAvg4 = sum(s1[15:19])/6 
	iterAvg5 = sum(s1[20:24])/6
	iterAvg6 = sum(s1[25:29])/6
	plt.plot(elems, [iterAvg1,iterAvg2,iterAvg3,iterAvg4,iterAvg5,iterAvg6], marker='.',label='Stream')
	
	iterAvg1 = sum(m1[0:4])/6 
	iterAvg2 = sum(m1[5:9])/6 
	iterAvg3 = sum(m1[10:14])/6 
	iterAvg4 = sum(m1[15:19])/6 
	iterAvg5 = sum(m1[20:24])/6
	iterAvg6 = sum(m1[25:29])/6
	plt.plot(elems, [iterAvg1,iterAvg2,iterAvg3,iterAvg4,iterAvg5,iterAvg6], marker='.',label='Managed')
	plt.xlabel('ELEM NUMBER')
	plt.ylabel('EVENT ELAPSED (ms)')
	plt.xticks(elems)
	plt.legend()
	plt.grid()
	plt.show()
