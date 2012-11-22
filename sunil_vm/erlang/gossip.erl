-module(gossip).
-import(matrix).
-compile(export_all).

start(Function,Input)->
	%P = generate_topology()
	P=matrix:new(10,10,fun (Column, Row, Columns, _) ->                      
	Columns * (Row - 1) + Column
	end),
	gossip(Function,P,Input).

gossip(Function,TransitionMatrix,Input) ->
	Pids = create(length(TransitionMatrix),[],TransitionMatrix,Input),
	sendpids(length(Pids),Pids),
	starttimer(Pids,Function).
	%we must get list of list which contains tuples of index and floating point no. for each node
	% [[(index, value)()()],[(index, value)()],..] fraglist= getfragmentlist(N) 
	% threadnodes <- create <- fraglist

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

create(0,Pids,TransitionMatrix,Input) -> Pids;
create(I,Pids,TransitionMatrix,Input)->
	%getfragments(I)
	Pid = spawn_link(fun() -> threadnodes(TransitionMatrix,[],initthread(I,Input)) end),
	create(I-1,  (Pids ++ [Pid]), TransitionMatrix, Input).

initthread(I,Input) -> 
	case Input of 
        identity -> [I];
        pushpull -> if
        	I == 1 ->
        		[1];
        	true -> [0]
        end
    end.	

calculate(Function,Myvalue,Value) ->
case Function of 
        max -> [erlang:max(hd(Myvalue),hd(Value))];
        min -> [erlang:min(hd(Myvalue),hd(Value))];
        mean ->[(hd(Myvalue) + hd(Value))/2];
        update -> [1]
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
<<<<<<< HEAD
        	io:format("tick~p ~n",[self()]),
       		self() ! {send,Function, Size},
            timer:send_after(1000, tick),
            threadnodes(TransitionMatrix,Pids,Myvalue,Size-1)
    end.
=======
       		self() ! {send,Function},
            timer:send_after(1000, {tick, Function}),
            threadnodes(TransitionMatrix,Pids,Myvalue)
    end.
>>>>>>> 1fc24d70911dfae2df26d317af3e1154f611793e
