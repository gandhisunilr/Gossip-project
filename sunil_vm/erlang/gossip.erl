-module(gossip).

-compile(export_all).

start(Function)->
	%P = generate_topology()
	P=matrix:new(3,3,fun (Column, Row, Columns, _) ->                      
	Columns * (Row - 1) + Column
	end),
	gossip(Function,P).

gossip(Function,TransitionMatrix) ->
	Pids = create(length(TransitionMatrix),[],TransitionMatrix),
	sendpids(length(Pids),Pids),
	starttimer(Pids,Function).
	% hd(Pids) ! {max, self(), 100},
	% receive
	%  	{returnmsg, Function, Pid, Value } ->
	%  		Value
	% end.

starttimer(Pids,Function) ->
	hd(Pids) ! {tick, Function},
	if
		length(Pids) /= 1 ->
			starttimer(tl(Pids), Function);
		true -> true
	end.

sendpids(0,Pids) -> 1;
sendpids(I,Pids) ->
	lists:nth(I,Pids) ! {pid, Pids},
	sendpids(I-1,Pids).

create(0,Pids,TransitionMatrix) -> Pids;
create(I,Pids,TransitionMatrix)->
	Pid = spawn_link(fun() -> threadnodes(TransitionMatrix,[],initthread(I)) end),
	create(I-1,  (Pids ++ [Pid]), TransitionMatrix ).

initthread(I) -> [I].

calculate(Function,Myvalue,Value) ->
case Function of 
        max -> [erlang:max(hd(Myvalue),hd(Value))];
        min -> [erlang:min(hd(Myvalue),hd(Value))];
        mean ->[(hd(Myvalue) + hd(Value))/2];
        update -> true
    end.

selectneighbours(TransitionMatrix, Pids, Pid) ->
	lists:nth(random:uniform(length(TransitionMatrix)), Pids).

printmsg(Function,Type,Printlist)->
case Type of
	return -> io:format("~p : ~p Received from ~p :~p Computing ~p ~n", [hd(Printlist),hd(lists:nth(2,Printlist)),lists:nth(3,Printlist),hd(lists:nth(4,Printlist)), Function]);
	returnmsg -> io:format("~p : ~p Received from ~p :~p Reply Computing ~p ~n", [hd(Printlist),hd(lists:nth(2,Printlist)),lists:nth(3,Printlist),hd(lists:nth(4,Printlist)), Function])
end.
	

threadnodes(TransitionMatrix,Pids,Myvalue) ->
	%getneighbours()
	%getfragments()
	receive
		%get the fucking pids of all processes,
        {pid, Pidsmsg } ->
        	io:format("Yay I Got Pids~p ~n",[self()]),
        	threadnodes(TransitionMatrix,Pidsmsg,Myvalue);
        
        %Send Function	This function must be executed after every few minutes
        {send, Function} ->
        	Pid=selectneighbours(TransitionMatrix, Pids, self()),
        	Pid ! {Function, self(), Myvalue},
        	threadnodes(TransitionMatrix,Pids, Myvalue);

        %Recieve Function from Process Pid with his value
        {Function, Pid, Value } ->
        	Pid ! { returnmsg, Function, self(), Myvalue },
        	printmsg(Function, return, [self(),Myvalue,Pid,Value]),
        	threadnodes(TransitionMatrix,Pids, calculate( Function, Myvalue,Value));

        %Reply Recieve Function from Process Pid with his value	
        {returnmsg, Function, Pid, Value } ->
        	printmsg(Function, returnmsg, [self(),Myvalue,Pid,Value]),
        	threadnodes(TransitionMatrix,Pids, calculate( Function, Myvalue,Value));

        {tick, Function}->
       		self() ! {send,Function},
            timer:send_after(1000, {tick, Function}),
            threadnodes(TransitionMatrix,Pids,Myvalue)
    end.