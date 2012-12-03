
******
README
******


Contents
########

1. gossip.erl

Implementation of Gossip algorithm for performing the following tasks.

1. Minimum 
2. Maximum 
3. Mean
4. Updation of contents in a fragment
5. Retrieval of contents in a fragment 


2. gossip_median.erl

Implementation of Gossip algorithm for computing median.

3. fragreader.erl

Reads random numbers stored in a file and generates a list of fragments with length equal to number of nodes.

4. lister.erl

Performs initialization of messages of each node in gossip based.

5. updateFound.erl

Performs updation, retrieval of values in a fragment.

6. getneighbours.erl

Reads the list of neighbours for each node from ptm.txt.

7. getsizeneighbours.erl

Read the number of neighbours for each node from neighbours.txt.

8. toperator.py

Generates the topology and number of neighbours for each node and writes to ptm.txt and neighbours.txt respectively.

9. generator.py

Generates the random number file 'randnofile'.

10. findconvergence.py

Determines whether gossip has converged.


Execution Order
###############

1. python generator.py 

%Generates the randnofile

2. erlc gossip.erl updateFound.erl fragreader.erl lister.erl getneighbours.erl getsizeneighbours.erl nolessthan.erl 

%Compiles all the erlang source code. Ignore the warnings.

3. python toperator.py 100 0.2 

%100 = Number of nodes, 0.2 = Neighbourhood threshold. Lower values of neighbourhood threshold might create a disconnected graph and cause Gossip to fail. Number of nodes more than 1500 takes a very long time to run. 

4. erl %Enter erlang interpreter

gossip:start(Function, fragment, Replication Factor, Input List)

Function can be one of the following

1. max - Compute the maximum value in randnofile.
2. min - Compute the minimum value in randnofile.
3. meanfragment - Compute the average of the values in randnofile. 
4. median - Compute the median of the values in randnofile.
5. update - Update the contents of fragment i at each node that may have a copy of it. The update originates at node 1 
6. retrieve - Retrieve the contents of fragment i from any node that may have an up-to-date copy of it. The retrieval is requested by node 1, with the user specifying the fragment number.  


Replication Factor - Number of times a value is replicated inside a fragment. Default = 1.

Input List = For specifying the index to be updated or retrieved by the user.

Generated Files
###############

1. randnofile - File with random numbers. By default has 20,000 floating point numbers.

2. ptm.txt - Probability Transition matrix in the form of list of tuples, each line corresponding to a node with it's own list of neighbours.

3. neighbours.txt - Each line corresponding to number of neighbours of a node.

4. gosssipvalues - Messages printed out by Gossip process during computation. Used to determine convergence.


Demo
####

For gossip.erl
##############

::

$ python generator.py

#Generates the randnofile with 20,000 numbers

$ erlc gossip.erl updateFound.erl fragreader.erl lister.erl getneighbours.erl getsizeneighbours.erl

gossip.erl:33: Warning: variable 'Function' is unused
gossip.erl:33: Warning: variable 'Pids' is unused
gossip.erl:37: Warning: variable 'X' is unused
gossip.erl:41: Warning: variable 'FragList' is unused
gossip.erl:41: Warning: variable 'Function' is unused
gossip.erl:41: Warning: variable 'Input' is unused
gossip.erl:41: Warning: variable 'InputList' is unused
gossip.erl:41: Warning: variable 'NeighboursListSize' is unused
gossip.erl:41: Warning: variable 'ReplicationFactor' is unused
gossip.erl:41: Warning: variable 'TransitionMatrix' is unused
gossip.erl:115: Warning: variable 'X' is unused
fragreader.erl:25: Warning: variable 'Factor' is unused
fragreader.erl:25: Warning: variable 'Nodes' is unused
fragreader.erl:25: Warning: variable 'Parts' is unused
fragreader.erl:28: Warning: variable 'Value' is unused
fragreader.erl:35: Warning: variable 'V' is unused
lister.erl:6: Warning: variable 'I' is unused
lister.erl:6: Warning: variable 'InputList' is unused
lister.erl:6: Warning: variable 'Op' is unused
lister.erl:21: Warning: variable 'X' is unused
lister.erl:37: Warning: variable 'X' is unused

#Ignore the warnings given by erl compiler. 

$ erl

Erlang R15B (erts-5.9) [source] [smp:4:4] [async-threads:0] [hipe] [kernel-poll:false]

Eshell V5.9  (abort with ^G)

1> gossip:start(max, fragment, 1, []).
Loaded
<0.39.0> : 98304.0034543 Received from <0.39.0> :98304.0034543 Computing max 
<0.40.0> : 99004.8042995 Received from <0.40.0> :99004.8042995 Computing max 
<0.41.0> : 99877.8226466 Received from <0.41.0> :99877.8226466 Computing max 
<0.42.0> : 99954.3990812 Received from <0.42.0> :99954.3990812 Computing max 
<0.43.0> : 99988.3446114 Received from <0.43.0> :99988.3446114 Computing max 
<0.44.0> : 99750.7318094 Received from <0.44.0> :99750.7318094 Computing max 
<0.48.0> : 99433.6450041 Received from <0.46.0> :99854.2964557 Computing max 
<0.46.0> : 99854.2964557 Received from <0.48.0> :99433.6450041 Reply Computing max 
<0.51.0> : 99508.4235213 Received from <0.51.0> :99508.4235213 Computing max 
<0.53.0> : 99025.2078432 Received from <0.53.0> :99025.2078432 Computing max 
<0.54.0> : 99916.7825264 Received from <0.54.0> :99916.7825264 Computing max 
<0.55.0> : 99404.5164212 Received from <0.55.0> :99404.5164212 Computing max 
<0.56.0> : 99878.1105886 Received from <0.56.0> :99878.1105886 Computing max 
<0.57.0> : 99690.3851611 Received from <0.57.0> :99690.3851611 Computing max 

2> 
User switch command
--> i
--> c
** exception exit: killed
2> 

# Gossip process prints the progress onto the terminal. To stop gossip, press Ctrl+G and user switch command mode.
From here, type in i, then c which stop the Gossip process and bring you back to a responsive shell. The longer Gossip process is executed the better convergence can be acheived.

2> Ctrl + G

type in q to quit the erl interpreter.


$ python findconvergence.py 100 99995.1859911 0.01
Converged after 4991 messages
Done


For gossip_median.erl
#####################

$ erlc gossip.erl updateFound.erl fragreader.erl lister.erl getneighbours.erl getsizeneighbours.erl nolessthan.erl

$ erl

1> gossip:start(median, fragment, 1, []).

#It prints onto the terminal that the range median value is in.