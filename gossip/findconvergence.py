import re

def findconvergence(Networksize,ActualValue, Percenterror):
	Pidmapping = {}
	threshold = (Percenterror/100) * ActualValue
	I = 0
	f = open('gossipvalues', 'r')
	for line in iter(f):
		I = I +1
		Myvalue = float(line.split(" ")[1])
		Pid = int(re.findall(r'<0.(.*).0>',line.split(" ")[0])[0])
		if (Myvalue - ActualValue) < threshold:
			Pidmapping[Pid]= 1
		else:
			Pidmapping[Pid]= 0

		if (len(Pidmapping) > Networksize) and (sum(Pidmapping.values()) > Networksize):
			print "Converged at Line"+str(I)
			break
	print "Done Checking"