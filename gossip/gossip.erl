-module(gossip).
-import(matrix).
-import(lister).
-import(updateFound).
-import(fragreader, [genfrags/1]).
-import(getneighbours).
-import(getsizeneighbours).
-compile(export_all).

start(Function,Input,InputList)->
	TransitionMatrix = getneighbours:getneighbours(ptm.txt),
    % This is named P because length of TransitionMatrix is same as siae of neighbours
    NeighboursListSize = getsizeneighbours:getsizeneighbours(neighbours.txt),
	% P=matrix:new(100,100,fun (Column, Row, Columns, _) ->                      
	% Columns * (Row - 1) + Column
	% end),
	gossip(Function,NeighboursListSize,TransitionMatrix,Input,InputList).

gossip(Function,NeighboursListSize, TransitionMatrix ,Input,InputList) ->
    FragList = genfrags(length(NeighboursListSize)),
	Pids = create(length(NeighboursListSize),[],NeighboursListSize,TransitionMatrix,Input,Function, FragList,InputList),
	sendpids(length(Pids),Pids,Function),
	starttimer(Pids,Function).
	

starttimer(Pids,Function) ->
	hd(Pids) ! {tick, Function},
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

create(0,Pids,NeighboursListSize,TransitionMatrix,Input,Function, FragList,InputList) -> Pids;
create(I,Pids,NeighboursListSize,TransitionMatrix,Input,Function, FragList,InputList)->
    Fragment = lists:nth(I, FragList),
    NeighboursList = element(1,lists:split(lists:nth(I,NeighboursListSize),TransitionMatrix)),
	Pid = spawn_link(fun() -> threadnodes(NeighboursListSize,NeighboursList,[],initthread(I,Input,Fragment,Function,InputList), Fragment, 0) end),
	create(I-1,  (Pids ++ [Pid]), NeighboursListSize, TransitionMatrix, Input,Function, FragList,InputList).

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
        meanfragments->[[(hd(Myvalue) + hd(Value))/2, (tl(Myvalue) + tl(Value))/(hd(Myvalue) + hd(Value))/2],Fragment,0];
        update -> updateFound:upFound(Myvalue, Value,Fragment, Function);
        retrieve -> Result = updateFound:upFound(Myvalue, Value, Fragment, Function),
        %    io:format("Result is ~p", [Result]),
            Head = hd(hd(Result)),
            Mycheck = element(1, hd(Myvalue)),
            Check = element(1, hd(Value)),
            if 
                Check /= 0, Mycheck == 0 -> 
                    if 
                        element(2, Head) /= 0  ->
                        io:format("Parent of found node ~p~n", [Parent]), 
                        io:format("Sending retrieve to ~p~n", [Pid]), 
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
	

threadnodes(NeighboursListSize,NeighboursList,Pids,Myvalue,Fragment,Parent) ->
	receive
		%get the pids of all processes,
        {pid, Pidsmsg } ->
        %	io:format("I am ~p and my value, fragment are ~p | ~p~n ",[self(), Myvalue, Fragment]),
        % 	threadnodes(NeighboursListSize,Pidsmsg, lister:retriever(Myvalue, Pidsmsg, self()), Fragment);
        	threadnodes(NeighboursListSize,NeighboursList, Pidsmsg, Myvalue, Fragment,Parent);
        
         {pid, Pidsmsg, retrieve} ->
       % 	io:format("Retrieve: I am ~p and my value, fragment are ~p | ~p~n ",[self(), Myvalue, Fragment]),
         	threadnodes(NeighboursListSize,NeighboursList, Pidsmsg, lister:retriever(Myvalue, Pidsmsg, self()), Fragment, Parent);
        
        %Send Function	This function must be executed after every few minutes
        {send, Function} ->
            {I, P} = hd(NeighboursList),
        	Pid=selectneighbours(NeighboursList, Pids,random:uniform(length(NeighboursListSize)),P,1,I),
        	Pid ! {Function, self(), Myvalue},
        	threadnodes(NeighboursListSize,NeighboursList, Pids,Myvalue,Fragment,Parent);

        %Recieve Function from Process Pid with his value
        {Function, Pid, Value } ->
        	Pid ! { returnmsg, Function, self(), Myvalue },
        %	printmsg(Function, return, [self(), Myvalue, Pid, Value]),
            ValueList = calculate(Function, Myvalue, Value, Fragment, Pid, Parent),
        %    io:format("Result in Recieve ~p", [ValueList]),
            threadnodes(NeighboursListSize,NeighboursList, Pids, lists:nth(1,ValueList),lists:nth(2,ValueList),lists:nth(3, ValueList));

        %Reply Recieve Function from Process Pid with his value	
        {returnmsg, Function, Pid, Value } ->
         %   printmsg(Function, returnmsg, [self(),Myvalue,Pid,Value]),
            ValueList = calculate(Function, Myvalue, Value, Fragment, Pid, Parent),
         %   io:format("Result in Returnmsg~p", [ValueList]),
            threadnodes(NeighboursListSize,NeighboursList, Pids, lists:nth(1,ValueList),lists:nth(2,ValueList),lists:nth(3, ValueList));

        {retrieve, Result} ->
            io:format("~p retrieve ~p ",[self(), hd(hd(Result))]),
            if self() /= tl(hd(Result)), Parent /= 0 -> Parent ! {retrieve, Result};
            true -> io:format("###Node 1 ~p Parent ~p retrieve ~p ~n###",[self(), Parent, hd(hd(Result))])
            end;

        {tick, Function}->
       		self() ! {send,Function},
            timer:send_after(1000, {tick, Function}),
            threadnodes(NeighboursListSize,NeighboursList, Pids,Myvalue,Fragment,Parent)
    end.
