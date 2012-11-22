-module(gossip).
-import(matrix).
-compile(export_all).

start()->
	%P = generate_topology()
	P=matrix:new(3,3,fun (Column, Row, Columns, _) ->                      
	Columns * (Row - 1) + Column
	end),
	gossip(max,P).

gossip(Function,TransitionMatrix) ->
	Pids = create(5,[],TransitionMatrix),
	sendpids(length(Pids),Pids),
	starttimer(Pids).
	% hd(Pids) ! {max, self(), 100},
	% receive
	%  	{returnmsg, Function, Pid, Value } ->
	%  		Value
	% end.

starttimer(Pids) ->
	hd(Pids) ! {tick, max},
	%hd(Pids) ! {pid, Pids },
	if
		length(Pids) /= 1 ->
			starttimer(tl(Pids));
		true -> true
	end.

sendpids(0,Pids) -> 1;
sendpids(I,Pids) ->
	lists:nth(I,Pids) ! {pid, Pids},
	sendpids(I-1,Pids).

create(0,Pids,TransitionMatrix) -> Pids;
create(I,Pids,TransitionMatrix)->
	Pid = spawn_link(fun() -> threadnodes(TransitionMatrix,[],I,5) end),
	create(I-1,  (Pids ++ [Pid]), TransitionMatrix ).

calculate(Function,Myvalue,Value) ->
case Function of 
        max -> erlang:max(Myvalue,Value);
        min -> erlang:min(Myvalue,Value);
        mean -> (Myvalue + Value)/2
    end.

selectneighbours(I) ->
	I-1.

threadnodes(TransitionMatrix,Pids,Myvalue,Size) ->
	%getneighbours()
	%getfragments()
	receive
		%get the fucking pids of all processes,
        {pid, Pidsmsg } ->
        	io:format("Yay I Got Pids~p ~n",[self()]),
        	threadnodes(TransitionMatrix,Pidsmsg,Myvalue,Size);
        
        %Send Function	This function must be executed after every few minutes
        {send, Function, N} ->
        	%N=selectneighbours(I),
        	if	N/=0 ->
        			Pid=lists:nth(N,Pids),
        			Pid ! {Function, self(), Myvalue},
        			threadnodes(TransitionMatrix,Pids, Myvalue,Size)
        	end;	

        %Recieve Function from Process Pid with his value
        {Function, Pid, Value } ->
        	Pid ! { returnmsg, Function, self(), Myvalue },
        	io:format("~p Received ~p from ~p My Value is ~p Computing ~p ~n", [self(),Value,Pid,Myvalue, Function]),
        	threadnodes(TransitionMatrix,Pids, calculate( Function, Myvalue,Value),Size);

        %Reply Recieve Function from Process Pid with his value	
        {returnmsg, Function, Pid, Value } ->
        	io:format("~p Reply Received ~p from ~p My Value is ~p Computing ~p ~n", [self(),Value,Pid,Myvalue, Function]),    	
        	threadnodes(TransitionMatrix,Pids, calculate( Function, Myvalue,Value),Size);

        {tick, Function}->
        	io:format("tick~p ~n",[self()]),
       		self() ! {send,Function, Size},
            timer:send_after(1000, tick),
            threadnodes(TransitionMatrix,Pids,Myvalue,Size-1)
    end.
