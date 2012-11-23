%Author: Primal

-module(network).
-compile(export_all). %TODO: Specify the functions in module interface

create_network(N) ->
    %TODO: Generate a markov chain for N nodes
    matrix:new(N,N,fun (Column, Row, Columns, _) ->                      
	Columns * (Row - 1) + Column
	end).

start(N, Function) ->
    spawn(?MODULE, init, [N, Function]). 

init(N) ->
    P = create_network(N),
    gossip(P, Function).

%TODO: Follow the design document    


