How to run the code
===================

Clone the git repository using 'git clone https://github.com/sunilgandhi007/Gossip-project.git'

Change directory into 'gossip' and start the erl interpreter

inside erl type 

1>c(gossip). #Ignore the warnings for now

2>gossip:start(max/min/mean/update/retrieve, identity/fragment, InputList = []/[{Index, Value)]).

Checking Whether network has converged or not:
findconvergence(Networksize,ActualValue, Percenterror)
Example
from findconvergence import *
findconvergence(1000,6.42360262825,0.001)