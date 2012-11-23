Design
=====

Interface Functions
===================
* start - start(N, function)
    N- Number of nodes, function - computational task

* init - init(N, function)
    Creates the PTM for network
    Start N processes which represent N nodes which waits for a message
    Invokes Gossip Process

Building the network
====================
* Network Topology : create_network(N), N - number of nodes, 
    Choose a value(0.25) as neighbourhood threshold and if distance of two nodes inside that make them neighbours
    probability assigned based on the function Dr. K has given

    Concern: How to make sure every node has at least one neighbour

    Concern: Associating each process(pid) with the row in PTM.

    
Gossip
======

* gossip(Function, P) 
    P - PTM
    For the first node, call getneighbours choose a neighbour(based on probability) and exchange values
    receive
        call getneighbours and choose a neighbour, do the computation, call gossip again
        

* get_neighbours(PID, P)
    PID - Process ID
    P - PTM
    choose a neighbour(based on probability) and exchange values
    
*      




