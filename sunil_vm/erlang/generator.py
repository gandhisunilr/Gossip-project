import random                                                  
f = open('randnofile', 'w')                                    
for x in range(1,1000):                                        
	f.write(str(random.uniform(1,100000)))
	f.write("\n")