import math


def generator(N=20):
	chain = [[0]*(N) for i in range(N)]


	chain[0][0] = 0.3
	chain[0][1] = 0.35
	chain[0][N-1] = 0.35


	for i in range(1, N-1):
		for j in range(1, N-1):
			if i == j:
				chain[i][j] = 0.3
				chain[i][j+1] = 0.35
				chain[i][j-1] = 0.35

		
	chain[i+1][j+1] = 0.3
	chain[i+1][j] = 0.35
	chain[i+1][0] = 0.35

#	for i in range(N):
#		print chain[i]

	print chain	
	return chain

if __name__	== "__main__":
	generator(10)	