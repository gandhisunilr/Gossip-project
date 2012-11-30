import math
import random
import sys


"""
Generates a topology with N nodes.
To run: python topgen.py N
Output: python topgen.py 5
[[0, 3, 0.25], [0, 0, 0.75]]
[[1, 2, 0.16666666666666666], [1, 4, 0.16666666666666666], [1, 1, 0.6666666666666667]]
[[2, 1, 0.16666666666666666], [2, 2, 0.8333333333333334]]
[[3, 2, 0.25], [3, 3, 0.75]]
[[4, 1, 0.16666666666666666], [4, 4, 0.8333333333333334]]
"""

def topology(N):
	Cords = generate_coordinates(N)
	Neighbours = []
	for i in range(N):
		Value = Cords[i]
		MyNeighbours = []
		for j in range(N):
			V2 = Cords[j]
			if is_neighbour(calculate_distance(Value[0], Value[1], V2[0], V2[1])):
				MyNeighbours.append(j)	
			else: continue
		if MyNeighbours == []:
			rand = int(random.random()*10%N) 	
			index = rand if rand != i else (rand + 1)%N 
			MyNeighbours.append(index)
		Neighbours.append(MyNeighbours)		

#	print Neighbours	
	Chain = generate_chain(N, Neighbours)	
	for C in Chain:
		print C

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
			Element.append([i, j, Other/2]) #Pij/2 Lazy 
		Element.append([i, i, (1 + (1 - SumOfOthers))/2]) #1 + Pij Lazy 	
		Chain.append(Element)
	return Chain




def calculate_distance(X0,Y0,X,Y):
	return math.sqrt((X-X0)**2 + (Y-Y0)**2)

def generate_coordinates(N):
	return [[random.random(), random.random()] for x in  range(N)]

def is_neighbour(Distance):
	if Distance >= 0.4 or Distance == 0.0:
		return False
	return True


if __name__	== "__main__":
	N = eval(sys.argv[1])
	topology(N)