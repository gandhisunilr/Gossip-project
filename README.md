How to run the code
===================

Clone the git repository using 'git clone https://github.com/sunilgandhi007/Gossip-project.git'

Change directory into 'gossip' and start the erl interpreter

inside erl type 

1>c(gossip). #Ignore the warnings for now

2>gossip:start(max, identity).

Change max into any function you wish to compute. {max, min, mean, update}

Format of variables :
1)Fragment : [{},{}]