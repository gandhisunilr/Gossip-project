import re
import sys

def findconvergence(Networksize,ActualValue, Percenterror):
	Pidmapping = {}
	threshold = (Percenterror/100) * ActualValue
	I = 0
	f = open('gossipvalues', 'r')
	for line in iter(f):
		I = I +1
		Myvalue = float(line.split(" ")[1])
		Pid = int(re.findall(r'<0.(\d*).*[0-9]>',line.split(" ")[0])[0])
		if abs(Myvalue - ActualValue) < threshold:
			Pidmapping[Pid]= 1
		else:
			Pidmapping[Pid]= 0

		if (len(Pidmapping) >= Networksize) and (sum(Pidmapping.values()) >= Networksize):
			print "Converged after %s messages"+str(I)
			NotConverged = False
			break
		else:
			NotConverged = True	
	if NotConverged:
		print "All nodes have not received the computed value."	
	print "Done"



if __name__	== "__main__":
	if len(sys.argv) != 4:
		print "Wrong Usage \nUsage: python findconvergence Networksize ActualValue Percenterror \
		\nExample: python findconvergence 100  99995.1859911 0.01"

 	elif len(sys.argv) == 4: 
 		Networksize, ActualValue, Percenterror = eval(sys.argv[1]), eval(sys.argv[2]), eval(sys.argv[3])
 		findconvergence(Networksize, ActualValue, Percenterror)