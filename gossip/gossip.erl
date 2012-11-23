-module(gossip).
-import(matrix).
-import(lcom).
-import(fragreader, [genfrags/1]).
-compile(export_all).

start(Function,Input)->
	%P = generate_topology()
	P=matrix:new(10,10,fun (Column, Row, Columns, _) ->                      
	Columns * (Row - 1) + Column
	end),
	gossip(Function,P,Input).

gossip(Function,TransitionMatrix,Input) ->
    Fraglist = genfrags(10),
	Pids = create(length(TransitionMatrix),[],TransitionMatrix,Input, FragList),
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

create(0,Pids,TransitionMatrix,Input, FragList) -> Pids;
create(I,Pids,TransitionMatrix,Input, FragList)->
    Fragment = lists:nth(I, FragList);
	Pid = spawn_link(fun() -> threadnodes(TransitionMatrix,[],initthread(I,Input), Fragment) end),
	create(I-1,  (Pids ++ [Pid]), TransitionMatrix, Input, FragList).

initthread(I,Input,F) -> 
	case Input of 
        identity -> [I];
        pushpull -> if
        	I == 1 ->
        		[1];
        	true -> [0]
        end
    end.	

getList(Key, L1, L2) ->
    case lists:keyfind(Key, 2, L1) /= false of
        true -> L1;
        false -> L2
    end.

calculate(Function,Myvalue,Value) ->
case Function of 
        %TODO: No need of passing around fragments, pass only the max, min and average of the fragment
        %TODO: No need of updating fragments, only that message passed aroung nodes
        max-> [erlang:max(hd(Myvalue), hd(Value))];
        min-> [erlang:min(hd(Myvalue), hd(Value))];
        mean-> [(hd(Myvalue) + hd(Value))/2];
        update -> [1]
    end.

selectneighbours(TransitionMatrix, Pids, Pid) ->
	lists:nth(random:uniform(length(TransitionMatrix)), Pids).

printmsg(Function,Type,Printlist)->
case Type of
	return -> io:format("~p : ~p Received from ~p :~p Computing ~p ~n", [hd(Printlist),hd(lists:nth(2,Printlist)),lists:nth(3,Printlist),hd(lists:nth(4,Printlist)), Function]);
	returnmsg -> io:format("~p : ~p Received from ~p :~p Reply Computing ~p ~n", [hd(Printlist),hd(lists:nth(2,Printlist)),lists:nth(3,Printlist),hd(lists:nth(4,Printlist)), Function])
end.
	

threadnodes(TransitionMatrix,Pids,Myvalue,Fragment) ->
	%getneighbours()
	receive
		%get the pids of all processes,
        {pid, Pidsmsg } ->
        	io:format("Yay I Got Pids~p ~n",[self()]),
        	threadnodes(TransitionMatrix,Pidsmsg,Myvalue,Fragment);
        
        %Send Function	This function must be executed after every few minutes
        {send, Function} ->
        	Pid=selectneighbours(TransitionMatrix, Pids, self()),
        	Pid ! {Function, self(), Myvalue},
        	threadnodes(TransitionMatrix,Pids,Myvalue,Fragment);

        %Recieve Function from Process Pid with his value
        {Function, Pid, Value } ->
        	Pid ! { returnmsg, Function, self(), Myvalue },
        	printmsg(Function, return, [self(),Myvalue,Pid,Value]),
        	threadnodes(TransitionMatrix,Pids, calculate(Function,Myvalue,Value),Fragment);

        %Reply Recieve Function from Process Pid with his value	
        {returnmsg, Function, Pid, Value } ->
        	printmsg(Function, returnmsg, [self(),Myvalue,Pid,Value]),
        	threadnodes(TransitionMatrix,Pids, calculate(Function, Myvalue,Value,Fragment));

        {tick, Function}->
       		self() ! {send,Function},
            timer:send_after(1000, {tick, Function}),
            threadnodes(TransitionMatrix,Pids,Myvalue,Fragment)
    end.
