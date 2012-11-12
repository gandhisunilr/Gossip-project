-module(gossip).

-compile(export_all).

start()->
	%P = generate_topology()
	P=matrix:new(3,3,fun (Column, Row, Columns, _) ->                      
	Columns * (Row - 1) + Column
	end),
	gossip(max,P).

gossip(Function,TransitionMatrix) ->
	Pids = create(5,[]),
	sendpids(length(Pids),Pids).

sendpids(0,Pids) -> 1;
sendpids(I,Pids) ->
	lists:nth(I,Pids) ! {pid, Pids},
	sendpids(I-1,Pids).


create(0,Pids) -> Pids;
create(I,Pids)->
	Pid = spawn_link(fun() -> threadnodes(I,[],I) end),
	create(I-1,  (Pids ++ [Pid]) ).

calculate(Function,Myvalue,Value) ->
case Function of 
        max -> erlang:max(Myvalue,Value);
        min -> erlang:min(Myvalue,Value);
        mean -> (Myvalue + Value)/2
    end.

threadnodes(TransitionMatrix,Pids,Myvalue) ->
	%getneighbours
	%getfragments
	receive
		%get the fucking pids
        {pid, Pids } ->
        	threadnodes(TransitionMatrix,Pids,Myvalue)
        {Function, Pid, Value } ->
        	Pid ! { returnmsg, Function, self(), Myvalue }
        	io:format("Yay I just received ~p and my Value is ~p and I am computing ~p ~n", [Value,Myvalue, Function]).
        	threadnodes(TransitionMatrix,Pids, erlang:calculate( Function, Myvalue,Value) )
        {Function, Pid, Value } ->
        	Pid ! { returnmsg, Function, self(), Myvalue }
        	io:format("Yay I just received ~p and my Value is ~p and I am computing ~p ~n", [Value,Myvalue, Function]).
        	threadnodes(TransitionMatrix,Pids, erlang:calculate( Function, Myvalue,Value) )	
    end.