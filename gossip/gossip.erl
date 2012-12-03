-module(gossip).
-import(matrix).
-import(lister).
-import(updateFound).
-import(fragreader, [genfrags/2]).
-import(getneighbours).
-import(getsizeneighbours).
-compile(export_all).

start(Function,Input,ReplicationFactor, InputList)->
    file:write_file("gossipvalues","",[write]),
	TransitionMatrix = getneighbours:getneighbours(ptm.txt),
    % This is named P because length of TransitionMatrix is same as siae of neighbours
    NeighboursListSize = getsizeneighbours:getsizeneighbours(neighbours.txt),
    io:format("Loaded"),
	gossip(Function,NeighboursListSize,TransitionMatrix,Input,ReplicationFactor,InputList).

gossip(Function,NeighboursListSize, TransitionMatrix ,Input,ReplicationFactor, InputList) ->
    FragList = genfrags(length(NeighboursListSize),ReplicationFactor),
	Pids = create(length(NeighboursListSize),[],NeighboursListSize,TransitionMatrix,Input,Function, FragList,ReplicationFactor,InputList),
	sendpids(length(Pids),Pids,Function),
	starttimer(Pids,Function).
	

starttimer(Pids,Function) ->
    hd(Pids)!{tick, Function},
	if
		length(Pids) /= 1 ->
			starttimer(tl(Pids), Function);
		true -> true
	end.

sendpids(0,Pids,Function) -> 1;
sendpids(I,Pids,Function) ->
    case Function of 
        retrieve -> lists:nth(I,Pids) ! {pid, Pids, retrieve};
        X -> lists:nth(I,Pids) ! {pid, Pids}
    end,
	sendpids(I-1,Pids,Function).

create(0,Pids,NeighboursListSize,TransitionMatrix,Input,Function, FragList,ReplicationFactor,InputList) -> Pids;
create(I,Pids,NeighboursListSize,TransitionMatrix,Input,Function, FragList,ReplicationFactor,InputList)->
    Fragment = lists:nth(I, FragList),
    Nodeno =(length(NeighboursListSize)-I) +1,
    PartitionList = lists:split(lists:nth(Nodeno,NeighboursListSize),TransitionMatrix),
    NeighboursList = element(1, PartitionList),
	Pid = spawn_link(fun() -> threadnodes(NeighboursListSize,NeighboursList,[],initthread(I,Input,Fragment,Function,InputList), Fragment,ReplicationFactor,0) end),
	create(I-1,  (Pids ++ [Pid]), NeighboursListSize, element(2, PartitionList), Input,Function, FragList,ReplicationFactor, InputList).

initthread(I,Input,Fragment,Function,InputList) -> 
	case Input of 
        identity -> [I];
        pushpull -> if
        	I == 1 ->
        		[1];
        	true -> [0]
        end;
        fragment -> 
        lister:getValue(I,Fragment,Function,InputList) 
    end.

calculate(Function,Myvalue,Value,Fragment,Pid, Parent) ->
case Function of 
        max-> [[erlang:max(hd(Myvalue), hd(Value))],Fragment,0];
        min-> [[erlang:min(hd(Myvalue), hd(Value))],Fragment,0];
        mean->[[(hd(Myvalue) + hd(Value))/2],Fragment,0];
        meanfragments->{K1,V1} = hd(Myvalue),
        {K2,V2} = hd(Value),
        [[{(K1 +K2)/2, (V1+V2)/2}],Fragment, 0];
        update -> updateFound:upFound(Myvalue, Value,Fragment, Function) ++ [0] ;
        retrieve -> Result = updateFound:upFound(Myvalue, Value, Fragment, Function),
            %io:format("Result is ~p", [Result]),
            Head = hd(hd(Result)),
            Mycheck = element(1, hd(Myvalue)),
            Check = element(1, hd(Value)),
            if 
                Check /= 0, Mycheck == 0 -> 
                    if 
                        element(2, Head) /= 0  ->
                        %io:format("Parent of found node ~p~n", [Parent]), 
                        %io:format("Sending retrieve to ~p~n", [Pid]), 
                        Pid ! {retrieve, Result};
                        true -> nothing
                    end,
                NewParent = Pid;
                true -> nothing,
           NewParent = Parent     
           end,
        Result ++ [NewParent]
        end.                 

selectneighbours(NeighboursList, Pids,R,Sum,Iteration,CurrentIndex) ->
	if
        R < Sum ->
            lists:nth(CurrentIndex, Pids);
        true ->
            NewSum = Sum + element(2,lists:nth(Iteration, NeighboursList)),
            NewCurrentIndex = element(1,lists:nth(Iteration, NeighboursList)),
            selectneighbours(NeighboursList,Pids,R,NewSum,Iteration +1,NewCurrentIndex)  
    end.

printmsg(Function,Type,Printlist)->
case Type of
	return -> io:format("~p : ~p Received from ~p :~p Computing ~p ~n", [hd(Printlist),hd(lists:nth(2,Printlist)),lists:nth(3,Printlist),hd(lists:nth(4,Printlist)), Function]);
	returnmsg -> io:format("~p : ~p Received from ~p :~p Reply Computing ~p ~n", [hd(Printlist),hd(lists:nth(2,Printlist)),lists:nth(3,Printlist),hd(lists:nth(4,Printlist)), Function])
end.
	
writeFile(Function, ValueList)->
    Temp = hd(lists:nth(1,ValueList)),
    case Function of
        meanfragments -> Number = element(1, Temp),
        Sum = element(2, Temp),
        Result = Sum/Number;
        update -> Result = element(1, Temp);
        X -> Result = Temp    
    end,
    file:write_file("gossipvalues",io_lib:fwrite("~p ~p\n", [self(), Result]),[append]).


threadnodes(NeighboursListSize,NeighboursList,Pids,Myvalue,Fragment,ReplicationFactor,Parent) ->
	receive
		%get the pids of all processes,
        {pid, Pidsmsg } ->
        %	io:format("I am ~p and my value, fragment are ~p | ~p~n ",[self(), Myvalue, Fragment]),
            random:seed(erlang:now()),
        	threadnodes(NeighboursListSize,NeighboursList, Pidsmsg, Myvalue, Fragment,ReplicationFactor,Parent);
        
         {pid, Pidsmsg, retrieve} ->
       % 	io:format("Retrieve: I am ~p and my value, fragment are ~p | ~p~n ",[self(), Myvalue, Fragment]),
         	threadnodes(NeighboursListSize,NeighboursList, Pidsmsg, lister:retriever(Myvalue, Pidsmsg, self()), Fragment,ReplicationFactor, Parent);
        
        %Send Function	This function must be executed after every few minutes
        {send, Function} ->
            {I, P} = hd(NeighboursList),
        	Pid=selectneighbours(NeighboursList, Pids,random:uniform(),P,1,I),
        	Pid ! {Function, self(), Myvalue},
        	threadnodes(NeighboursListSize,NeighboursList, Pids,Myvalue,Fragment,ReplicationFactor, Parent);

        %Recieve Function from Process Pid with his value
        {Function, Pid, Value } ->
        	Pid ! { returnmsg, Function, self(), Myvalue },
        	printmsg(Function, return, [self(), Myvalue, Pid, Value]),
            ValueList = calculate(Function, Myvalue, Value, Fragment, Pid, Parent),
            writeFile(Function, ValueList),writeFile(Function, ValueList),
            threadnodes(NeighboursListSize,NeighboursList, Pids, lists:nth(1,ValueList),lists:nth(2,ValueList),ReplicationFactor, lists:nth(3, ValueList));

        %Reply Recieve Function from Process Pid with his value	
        {returnmsg, Function, Pid, Value } ->
            printmsg(Function, returnmsg, [self(),Myvalue,Pid,Value]),
            ValueList = calculate(Function, Myvalue, Value, Fragment, Pid, Parent),
            writeFile(Function, ValueList),
            threadnodes(NeighboursListSize,NeighboursList, Pids, lists:nth(1,ValueList),lists:nth(2,ValueList),ReplicationFactor,lists:nth(3, ValueList));

        {retrieve, Result} ->
            io:format("~p retrieve ~p ",[self(), hd(hd(Result))]),
            if self() /= tl(hd(Result)), Parent /= 0 -> Parent ! {retrieve, Result};
            true -> io:format("###Node 1 ~p Parent ~p retrieve ~p ~n###",[self(), Parent, hd(hd(Result))])
            end;

        {tick, Function}->
       		self() ! {send,Function},
            timer:send_after(1000, {tick, Function}),
            threadnodes(NeighboursListSize,NeighboursList, Pids,Myvalue,Fragment,ReplicationFactor,Parent)
    end.
