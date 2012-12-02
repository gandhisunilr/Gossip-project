import random                                                  
f = open('randnofile', 'w')                                    
for x in range(1,50001):                                        
	f.write(str(random.random()*10*(random.uniform(1,100000))%100000))
	f.write("\n")