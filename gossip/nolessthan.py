def nolessthan(value):
	with open('randnofile') as f:
		lines = f.read().splitlines()
	numbers = list(map(float, lines))
	len([x for x in numbers if x >= 53088.213058])