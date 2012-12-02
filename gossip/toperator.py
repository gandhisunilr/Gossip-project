import math
import random
import sys


"""
Generates a topology with N nodes with the number of neighbours determined by Neighbourhood threshold.

N number of random coordinates are generated in the coordinate space [0,1). For determining neighbours 
a coordinate is chosen from the list of coordinates and the distance between that coordinate and rest 
of the neighbours is calculated. If the distance falls under a value as specified by Radius, it is added
as a neighbour otherwise it is ignored. 

After the above step each node has a list of neighbours associated with it. To calculate transition probabilities
for the markov chain, the method given by Dr. K based on degree of nodes was used. Also it was made sure that PTM  
is lazy by averaging it with Identity matrix.

Output: Neighbours.txt, ptm.txt

"""

def topology(N,Radius):
	Cords = generate_coordinates(N)
	Neighbours = []
	for i in range(N):
		Value = Cords[i]
		MyNeighbours = []
		for j in range(N):
			V2 = Cords[j]
			if is_neighbour(calculate_distance(Value[0], Value[1], V2[0], V2[1]), Radius):
				MyNeighbours.append(j)	
			else: continue 

#		if MyNeighbours == []:
#			rand = int(random.random()*10%N) 	
#			index = rand if rand != i else (rand + 1)%N 
#			MyNeighbours.append(index)
		Neighbours.append(MyNeighbours)		

	Chain = generate_chain(N, Neighbours)	
	f = open('ptm.txt', 'w')
	g = open('neighbours.txt', 'w')
	result = ""
	for Cha in Chain:
		g.write(str(len(Cha)))
		g.write('\n')
		result += " ".join(",".join(map(str,row)) for row in Cha)
		result += "\n"
 	f.write(result)


def generate_chain(N, Neighbours):

	Chain = []
	for i in range(N):
		Nebo = Neighbours[i]
		Element = []
		SumOfOthers = 0
		for j in Nebo:
			Bone = Neighbours[j]
			Other = 1/(1 + float((max(len(Nebo),len(Bone)))))
			SumOfOthers += Other 
			Element.append([j+1, Other/2]) #Pij/2 Lazy 
		Element.append([i+1, (1 + (1 - SumOfOthers))/2]) #1 + Pij Lazy 	
		Chain.append(Element)
	return Chain


def calculate_distance(X0,Y0,X,Y):
	return math.sqrt((X-X0)**2 + (Y-Y0)**2)

def generate_coordinates(N):
	return [[random.random(), random.random()] for x in  range(N)]

def is_neighbour(Distance, Radius):
	if Distance >= Radius or Distance == 0.0:
		return False
	return True


if __name__	== "__main__":
	N, Radius = eval(sys.argv[1]), eval(sys.argv[2])
	topology(N, Radius)