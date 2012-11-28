def nolessthan(value):
	with open('randnofile') as f:
		lines = f.read().splitlines()
	numbers = list(map(float, lines))
	return len([x for x in numbers if x <= value])