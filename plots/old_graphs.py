				
				
				
				
				
			
			
			
			
				
	#speedUp1 = o/f
	#speedUp2 = o/s
	#speedUp3 = o/m	
	#print("\nFuture speedup: ")
	#print(speedUp1)	
	#print("\nStream speedup: ")
	#print(speedUp2)
	#print("\nManaged Memory Stream speedup: ")
	#print(speedUp3)
	
	
	######################
	########GRAPHS########
	######################	
	
	
	
	#N=3584 COMPARISON
	fig=plt.figure(1)
	
	ax = fig.add_subplot(111)
	
	ax.plot(time, Swdown, '-', label = 'Swdown')
	ax.plot(time, Rn, '-', label = 'Rn')
	ax2 = ax.twinx()
	ax2.plot(time, temp, '-r', label = 'temp')
	ax.legend(loc=0)
	ax.grid()
	ax.set_xlabel("Time (h)")
	ax.set_ylabel(r"Radiation ($MJ\,m^{-2}\,d^{-1}$)")
	ax2.set_ylabel(r"Temperature ($^\circ$C)")
	ax2.set_ylim(0, 35)
	ax.set_ylim(-20,100)
	plt.show()
	
	
	
	plt.plot(iterNum, f1[5:10], marker='.',label='Future')
	
	plt.plot(iterNum, s1[5:10], marker='.',label='Stream ')

	plt.plot(iterNum, m1[5:10], marker='.',label='Managed')
	plt.xlabel('ELEM NUMBER')
	plt.ylabel('EVENT ELAPSED 3584 ELEMS \n (ms)')
	
	#plt.xscale('log',basex=2)
	plt.xticks(iterNum)
	plt.xscale('log',basex=5)
	plt.legend(loc='upper left')
	plt.grid()
	plt.show()
	
	#N=14336 COMPARISON
	plt.figure(2)
	
	plt.plot(iterNum, f1[15:20], marker='.',label='Future')
	
	plt.plot(iterNum, s1[15:20], marker='.',label='Stream ')

	plt.plot(iterNum, m1[15:20], marker='.',label='Managed')
	plt.xlabel('ELEM NUMBER')
	plt.ylabel('EVENT ELAPSED 14336 ELEMS \n (ms)')
	#plt.xticks(elems)
	#plt.xscale('log',basex=2)
	plt.xticks(iterNum)
	plt.xscale('log',basex=5)
	plt.legend(loc='upper left')
	plt.grid()
	plt.show()

	#N=57344 COMPARISON
	plt.figure(3)
	
	plt.plot(iterNum, f1[25:30], marker='.',label='Future')
	
	plt.plot(iterNum, s1[25:30], marker='.',label='Stream ')

	plt.plot(iterNum, m1[25:30], marker='.',label='Managed')
	plt.xlabel('ELEM NUMBER')
	plt.ylabel('EVENT ELAPSED 57344 ELEMS \n (ms)')
	#plt.xticks(elems)
	#plt.xscale('log',basex=2)
	plt.xticks(iterNum)
	plt.xscale('log',basex=5)
	plt.legend(loc='upper left')
	plt.grid()
	plt.show()
	
	
	
	
	#M=250 COMPARISON
	plt.figure(4)
	
	plt.plot(elems, [f1[2],f1[7],f1[12],f1[17],f1[22],f1[27]], marker='.',label='Future')
	
	plt.plot(elems, [s1[2],s1[7],s1[12],s1[17],s1[22],s1[27]], marker='.',label='Stream ')

	plt.plot(elems, [m1[2],m1[7],m1[12],m1[17],m1[22],m1[27]], marker='.',label='Managed')
	plt.xlabel('ELEM NUMBER')
	plt.ylabel('EVENT ELAPSED 250 KER ITER \n (ms)')
	
	plt.xscale('log',basex=2)
	#plt.xticks(elems)
	plt.legend(loc='upper left')
	plt.grid()
	plt.show()
	
	#M=1250 COMPARISON
	plt.figure(5)
	
	plt.plot(elems, [f1[3],f1[8],f1[13],f1[18],f1[23],f1[28]], marker='.',label='Future')
	
	plt.plot(elems, [s1[3],s1[8],s1[13],s1[18],s1[23],s1[28]], marker='.',label='Stream ')

	plt.plot(elems, [m1[3],m1[8],m1[13],m1[18],m1[23],m1[28]], marker='.',label='Managed')
	plt.xlabel('ELEM NUMBER')
	plt.ylabel('EVENT ELAPSED 1250 KER ITER \n (ms)')
	#plt.xticks(elems)
	plt.xscale('log',basex=2)
	plt.legend(loc='upper left')
	plt.grid()
	plt.show()

	#M=2500 COMPARISON
	plt.figure(6)
	
	plt.plot(elems, [f1[4],f1[9],f1[14],f1[19],f1[24],f1[29]], marker='.',label='Future')
	
	plt.plot(elems, [s1[4],s1[9],s1[14],s1[19],s1[24],s1[29]], marker='.',label='Stream ')

	plt.plot(elems, [m1[4],m1[9],m1[14],m1[19],m1[24],m1[29]], marker='.',label='Managed')
	plt.xlabel('ELEM NUMBER')
	plt.ylabel('EVENT ELAPSED 2500 KER ITER \n (ms)')
	#plt.xticks(elems)
	plt.xscale('log',basex=2)
	plt.legend(loc='upper left')
	plt.grid()
	plt.show()
	
	#COMPARE ALL ITERS
	
	plt.figure(7)
	
	plt.plot(elems, [f1[2],f1[7],f1[12],f1[17],f1[22],f1[27]], marker='o',label='Future 250', color='blue', linestyle=':')	
	plt.plot(elems, [s1[2],s1[7],s1[12],s1[17],s1[22],s1[27]], marker='o',label='Stream 250',color='green', linestyle=':')
	plt.plot(elems, [m1[2],m1[7],m1[12],m1[17],m1[22],m1[27]], marker='o',label='Managed 250',color='red', linestyle=':')
	
	plt.plot(elems, [f1[3],f1[8],f1[13],f1[18],f1[23],f1[28]], marker='v',label='Future 1250',color='blue', linestyle='--')	
	plt.plot(elems, [s1[3],s1[8],s1[13],s1[18],s1[23],s1[28]], marker='v',label='Stream 1250',color='green', linestyle='--')
	plt.plot(elems, [m1[3],m1[8],m1[13],m1[18],m1[23],m1[28]], marker='v',label='Managed 1250',color='red', linestyle='--')
	
	plt.plot(elems, [f1[4],f1[9],f1[14],f1[19],f1[24],f1[29]], marker='s',label='Future 2500',color='blue')	
	plt.plot(elems, [s1[4],s1[9],s1[14],s1[19],s1[24],s1[29]], marker='s',label='Stream 2500',color='green')
	plt.plot(elems, [m1[4],m1[9],m1[14],m1[19],m1[24],m1[29]], marker='s',label='Managed 2500',color='red')
	
	plt.xlabel('ELEM NUMBER')
	plt.ylabel('EVENT ELAPSED (ms)')
	
	plt.xscale('log',basex=2)
	#plt.xticks(elems)
	plt.legend(loc='upper left')
	plt.grid()
	plt.show()
	
	


	
	#SPEEDUP
	plt.figure(8)
	plt.plot(elems,  [speedUp1[2],speedUp1[7],speedUp1[12],speedUp1[17],speedUp1[22],speedUp1[27]], marker='o',label='Future 250',color='blue')
	plt.plot(elems,  [speedUp2[2],speedUp2[7],speedUp2[12],speedUp2[17],speedUp2[22],speedUp2[27]], marker='o',label='Stream 250',color='green')
	plt.plot(elems,  [speedUp3[2],speedUp3[7],speedUp3[12],speedUp3[17],speedUp3[22],speedUp3[27]], marker='o',label='Managed 250',color='red')
	plt.plot(elems, elems, marker='.',label='Ideal speed up',color='orange',linestyle='--')
	plt.xlabel('ELEM NUMBER')
	plt.ylabel('SPEEDUP')
	#plt.xticks(elems)

	
	plt.xlim([elems[0],elems[5]])
	plt.ylim([elems[0],elems[5]])
	
	plt.xscale('log',basex=2)
	plt.yscale('log',basey=2)
	
	plt.legend(loc='upper left')
	
	plt.grid()
	plt.show()
	
	
	plt.figure(9)
	plt.plot(elems, [speedUp1[3],speedUp1[8],speedUp1[13],speedUp1[18],speedUp1[23],speedUp1[28]], marker='v',label='Future 1250',color='blue')
	plt.plot(elems, [speedUp2[3],speedUp2[8],speedUp2[13],speedUp2[18],speedUp2[23],speedUp2[28]], marker='v',label='Stream 1250',color='green')
	plt.plot(elems, [speedUp3[3],speedUp3[8],speedUp3[13],speedUp3[18],speedUp3[23],speedUp3[28]], marker='v',label='Managed 1250',color='red')
	
	plt.plot(elems, elems, marker='.',label='Ideal speed up',color='orange',linestyle='--')
	plt.xlabel('ELEM NUMBER')
	plt.ylabel('SPEEDUP')
	#plt.xticks(elems)

	
	plt.xlim([elems[0],elems[5]])
	plt.ylim([elems[0],elems[5]])
	
	plt.xscale('log',basex=2)
	plt.yscale('log',basey=2)
	
	plt.legend(loc='upper left')
	
	plt.grid()
	plt.show()
	
	plt.figure(10)		
	plt.plot(elems, [speedUp1[4],speedUp1[9],speedUp1[14],speedUp1[19],speedUp1[24],speedUp1[29]], marker='s',label='Future 2500',color='blue')
	plt.plot(elems, [speedUp2[4],speedUp2[9],speedUp2[14],speedUp2[19],speedUp2[24],speedUp2[29]], marker='s',label='Stream 2500',color='green')
	plt.plot(elems, [speedUp3[4],speedUp3[9],speedUp3[14],speedUp3[19],speedUp3[24],speedUp3[29]], marker='s',label='Managed speed up 2500',color='red')
	

	
	plt.plot(elems, elems, marker='.',label='Ideal speed up',color='orange',linestyle='--')
	plt.xlabel('ELEM NUMBER')
	plt.ylabel('SPEEDUP')
	#plt.xticks(elems)

	
	plt.xlim([elems[0],elems[5]])
	plt.ylim([elems[0],elems[5]])
	
	plt.xscale('log',basex=2)
	plt.yscale('log',basey=2)
	
	plt.legend(loc='upper left')
	
	plt.grid()
	plt.show()
