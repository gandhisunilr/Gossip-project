-module(gossip).
-import(matrix).
-import(lister).
-import(updateFound).
-import(fragreader, [genfrags/2]).
-compile(export_all).

start(Function,Input,ReplicationFactor, InputList)->
	%P = generate_topology()
	P=matrix:new(100,100,fun (Column, Row, Columns, _) ->                      
	Columns * (Row - 1) + Column
	end),
	gossip(Function,P,Input,ReplicationFactor, InputList).

gossip(Function,TransitionMatrix,Input,ReplicationFactor, InputList) ->
    FragList = genfrags(length(TransitionMatrix),ReplicationFactor),
	Pids = create(length(TransitionMatrix),[],TransitionMatrix,Input,Function, FragList,ReplicationFactor,InputList),
	sendpids(length(Pids),Pids),
	starttimer(Pids,Function).
	

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

create(0,Pids,TransitionMatrix,Input,Function, FragList,ReplicationFactor, InputList) -> Pids;
create(I,Pids,TransitionMatrix,Input,Function, FragList,ReplicationFactor, InputList)->
    Fragment = lists:nth(I, FragList),
	Pid = spawn_link(fun() -> threadnodes(TransitionMatrix,[],initthread(I,Input,Fragment,Function,InputList), Fragment,ReplicationFactor) end),
	create(I-1,  (Pids ++ [Pid]), TransitionMatrix, Input,Function, FragList,ReplicationFactor, InputList).

initthread(I,Input,Fragment,Function,InputList) -> 
	case Input of 
        identity -> [I];
        pushpull -> if
        	I == 1 ->
        		[1];
        	true -> [0]
        end;
        fragment -> 
        lister:getValue(I,Fragment, Function,InputList) 
    end.

calculate(Function,Myvalue,Value,Fragment) ->
case Function of 
        max-> [[erlang:max(hd(Myvalue), hd(Value))],Fragment];
        min-> [[erlang:min(hd(Myvalue), hd(Value))],Fragment];
        mean->[[(hd(Myvalue) + hd(Value))/2],Fragment];
        meanfragments->
        {K1,V1} = hd(Myvalue),
        {K2,V2} = hd(Value),
        [[{(K1 +K2)/2, (V1+V2)/2}],Fragment];
        update -> updateFound:upFound(Myvalue, Value,Fragment)
    end.

selectneighbours(TransitionMatrix, Pids, Pid) ->
	lists:nth(random:uniform(length(TransitionMatrix)), Pids).

printmsg(Function,Type,Printlist)->
case Type of
	return -> io:format("~p : ~p Received from ~p :~p Computing ~p ~n", [hd(Printlist),hd(lists:nth(2,Printlist)),lists:nth(3,Printlist),hd(lists:nth(4,Printlist)), Function]);
	returnmsg -> io:format("~p : ~p Received from ~p :~p Reply Computing ~p ~n", [hd(Printlist),hd(lists:nth(2,Printlist)),lists:nth(3,Printlist),hd(lists:nth(4,Printlist)), Function])
end.
	

threadnodes(TransitionMatrix,Pids,Myvalue,Fragment,ReplicationFactor) ->
    %TODO: Do we need Myvalue as it can be calculated from Fragment?
	%getneighbours()
	receive
		%get the pids of all processes,
        {pid, Pidsmsg } ->
        	%io:format("I am ~p and my value, fragment are ~p | ~p~n ",[self(), Myvalue, Fragment]),
        	threadnodes(TransitionMatrix,Pidsmsg,Myvalue,Fragment,ReplicationFactor);
        
        %Send Function	This function must be executed after every few minutes
        {send, Function} ->
        	Pid=selectneighbours(TransitionMatrix, Pids, self()),
        	Pid ! {Function, self(), Myvalue},
        	threadnodes(TransitionMatrix,Pids,Myvalue,Fragment,ReplicationFactor);

        %Recieve Function from Process Pid with his value
        {Function, Pid, Value } ->
        	Pid ! { returnmsg, Function, self(), Myvalue },
        	printmsg(Function, return, [self(), Myvalue, Pid, Value]),
            threadnodes(TransitionMatrix,Pids, lists:nth(1,calculate( Function, Myvalue,Value,Fragment)),lists:nth(2,calculate( Function, Myvalue,Value,Fragment)),ReplicationFactor);

        %Reply Recieve Function from Process Pid with his value	
        {returnmsg, Function, Pid, Value } ->
            printmsg(Function, returnmsg, [self(),Myvalue,Pid,Value]),
            threadnodes(TransitionMatrix,Pids, lists:nth(1,calculate( Function, Myvalue,Value,Fragment)),lists:nth(2,calculate( Function, Myvalue,Value,Fragment)),ReplicationFactor);
            
        {tick, Function}->
       		self() ! {send,Function},
            timer:send_after(1000, {tick, Function}),
            threadnodes(TransitionMatrix,Pids,Myvalue,Fragment,ReplicationFactor)
    end.
