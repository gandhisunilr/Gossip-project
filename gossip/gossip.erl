-module(gossip).
-import(matrix).
-import(lister).
-import(fragreader, [genfrags/1]).
-compile(export_all).

start(Function,Input)->
	%P = generate_topology()
	P=matrix:new(10,10,fun (Column, Row, Columns, _) ->                      
	Columns * (Row - 1) + Column
	end),
	gossip(Function,P,Input).

gossip(Function,TransitionMatrix,Input) ->
    FragList = genfrags(10),
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
    Fragment = lists:nth(I, FragList),
	Pid = spawn_link(fun() -> threadnodes(TransitionMatrix,[],initthread(I,Input), Fragment) end),
	create(I-1,  (Pids ++ [Pid]), TransitionMatrix, Input, FragList).

initthread(I,Input) -> 
	case Input of 
        identity -> [I];
        pushpull -> if
        	I == 1 ->
        		[1];
        	true -> [0]
        end
    end.	

%Updates the fragment if the Value found otherwise returns.    
upFound(Myvalue, Value) ->
    {K, V} = Value,
    case lists:keyfind(K, 1, Myvalue) of
        false -> Myvalue;
        X -> [Value|lists:delete(X, Myvalue)]
    end.
    

calculate(Function,Myvalue,Value) ->
case Function of 
        max-> [erlang:max(hd(Myvalue), hd(Value))];
        min-> [erlang:min(hd(Myvalue), hd(Value))];
        mean-> [(hd(Myvalue) + hd(Value))/2, (tl(Myvalue) + tl(Value))/(hd(Myvalue) + hd(Value))/2];
        update -> [Value, upFound(Myvalue, Value)] %[Value, UpdatedValueOfFragment] 
    end.

selectneighbours(TransitionMatrix, Pids, Pid) ->
	lists:nth(random:uniform(length(TransitionMatrix)), Pids).

printmsg(Function,Type,Printlist)->
case Type of
	return -> io:format("~p : ~p Received from ~p :~p Computing ~p ~n", [hd(Printlist),hd(lists:nth(2,Printlist)),lists:nth(3,Printlist),hd(lists:nth(4,Printlist)), Function]);
	returnmsg -> io:format("~p : ~p Received from ~p :~p Reply Computing ~p ~n", [hd(Printlist),hd(lists:nth(2,Printlist)),lists:nth(3,Printlist),hd(lists:nth(4,Printlist)), Function])
end.
	

threadnodes(TransitionMatrix,Pids,Myvalue,Fragment) ->
    %TODO: Do we need Myvalue as it can be calculated from Fragment?
	%getneighbours()
	receive
		%get the pids of all processes,
        {pid, Pidsmsg } ->
        	io:format("I am ~p and my value, fragment are ~p | ~p~n ",[self(), Myvalue, Fragment]),
        	threadnodes(TransitionMatrix,Pidsmsg,Myvalue,Fragment);
        
        %Send Function	This function must be executed after every few minutes
        {send, Function} ->
        	Pid=selectneighbours(TransitionMatrix, Pids, self()),
        	Pid ! {Function, self(), lister:summarize(Fragment, Function)},
        	threadnodes(TransitionMatrix,Pids,Myvalue,Fragment);

        %Recieve Function from Process Pid with his value
        {Function, Pid, Value } ->
            FunValue = lister:summarize(Fragment, Function),
        	Pid ! { returnmsg, Function, self(), FunValue },
        	printmsg(Function, return, [self(), FunValue, Pid, Value]),
            Result = calculate(Function, FunValue, Value),
            if 
                Function == update ->
        	        threadnodes(TransitionMatrix,Pids, hd(Result), tl(Result));
                true -> threadnodes(TransitionMatrix, Pids, Result, Fragment)
            end;

        %Reply Recieve Function from Process Pid with his value	
        {returnmsg, Function, Pid, Value } ->
            FunValue = lister:summarize(Fragment, Function),
        	printmsg(Function, returnmsg, [self(), FunValue,Pid,Value]),
            Result = calculate(Function, FunValue, Value),
            if 
                Function == update ->
        	        threadnodes(TransitionMatrix,Pids, hd(Result), tl(Result));
                true -> threadnodes(TransitionMatrix, Pids, Result, Fragment)
            end;

        {tick, Function}->
       		self() ! {send,Function},
            timer:send_after(1000, {tick, Function}),
            threadnodes(TransitionMatrix,Pids,Myvalue,Fragment)
    end.
