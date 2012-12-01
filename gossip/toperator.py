import math
import random
import sys


"""
Generates a topology with N nodes.
To run: python topgen.py N
Output: python topgen.py 10
[[0, 3, 0.1], [0, 6, 0.1], [0, 7, 0.1], [0, 8, 0.1], [0, 0, 0.6]]
[[1, 4, 0.125], [1, 9, 0.16666666666666666], [1, 1, 0.7083333333333334]]
[[2, 4, 0.125], [2, 5, 0.16666666666666666], [2, 2, 0.7083333333333334]]
[[3, 0, 0.1], [3, 6, 0.1], [3, 8, 0.125], [3, 3, 0.675]]
[[4, 1, 0.125], [4, 2, 0.125], [4, 9, 0.125], [4, 4, 0.625]]
[[5, 2, 0.16666666666666666], [5, 9, 0.16666666666666666], [5, 5, 0.6666666666666667]]
[[6, 0, 0.1], [6, 3, 0.1], [6, 7, 0.1], [6, 8, 0.1], [6, 6, 0.6]]
[[7, 0, 0.1], [7, 2, 0.125], [7, 6, 0.1], [7, 7, 0.675]]
[[8, 0, 0.1], [8, 3, 0.125], [8, 6, 0.1], [8, 8, 0.675]]
[[9, 1, 0.16666666666666666], [9, 2, 0.16666666666666666], [9, 9, 0.6666666666666667]]

"""

""" Degree Variance """

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

def is_neighbour(Distance):
	if Distance >= 0.1 or Distance == 0.0:
		return False
	return True


if __name__	== "__main__":
	N = eval(sys.argv[1])
	topology(N)