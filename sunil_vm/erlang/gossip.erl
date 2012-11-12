-module(gossip).

-compile(export_all).

start()->
	%P = generate_topology()
	P=matrix:new(3,3,fun (Column, Row, Columns, _) ->                      
	Columns * (Row - 1) + Column
	end),
	gossip(max,P).

gossip(Function,TransitionMatrix) ->
	Pids = create(5,[],TransitionMatrix),
	sendpids(length(Pids),Pids).
	% hd(Pids) ! {max, self(), 100},
	% receive
	% 	{returnmsg, Function, Pid, Value } ->
	% 		Value
	% end.

sendpids(0,Pids) -> 1;
sendpids(I,Pids) ->
	lists:nth(I,Pids) ! {pid, Pids},
	sendpids(I-1,Pids).


create(0,Pids,TransitionMatrix) -> Pids;
create(I,Pids,TransitionMatrix)->
	Pid = spawn_link(fun() -> threadnodes(TransitionMatrix,[],I) end),
	create(I-1,  (Pids ++ [Pid]), TransitionMatrix ).

calculate(Function,Myvalue,Value) ->
case Function of 
        max -> erlang:max(Myvalue,Value);
        min -> erlang:min(Myvalue,Value);
        mean -> (Myvalue + Value)/2
    end.

selectneighbours(I) ->
	I-1.

threadnodes(TransitionMatrix,Pids,Myvalue) ->
	%getneighbours()
	%getfragments()
	receive
		%get the fucking pids of all processes
        {pid, Pids } ->
        	threadnodes(TransitionMatrix,Pids,Myvalue);
        %Recieve Function from Process Pid with his value
        {Function, Pid, Value } ->
        	Pid ! { returnmsg, Function, self(), Myvalue },
        	io:format("Yay I just received ~p and my Value is ~p and I am computing ~p ~n", [Value,Myvalue, Function]),
        	threadnodes(TransitionMatrix,Pids, calculate( Function, Myvalue,Value) );
        %Reply Recieve Function from Process Pid with his value	
        {returnmsg, Function, Pid, Value } ->
        	io:format("Reply ~p and my Value is ~p and I am computing ~p ~n", [Value,Myvalue, Function]),
        	threadnodes(TransitionMatrix,Pids, erlang:calculate( Function, Myvalue,Value) );
        %Send Function
        {start} ->
        	I=selectneighbours(I),
        	
    end.