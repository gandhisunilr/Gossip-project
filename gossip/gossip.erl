-module(gossip).
-import(matrix).
-import(lister).
-import(updateFound).
-import(fragreader, [genfrags/2]).
-import (nolessthan,[nolessthan/2]).
-import(getneighbours).
-import(getsizeneighbours).
-compile(export_all).

start(Function,Input,ReplicationFactor,InputList)->
	TransitionMatrix = getneighbours:getneighbours(ptm.txt),
    % This is named P because length of TransitionMatrix is same as siae of neighbours
    NeighboursListSize = getsizeneighbours:getsizeneighbours(neighbours.txt),
    io:format("Loaded"),
    gossip(Function,NeighboursListSize,TransitionMatrix,Input,ReplicationFactor,InputList).

gossip(Function,NeighboursListSize, TransitionMatrix ,Input,ReplicationFactor, InputList) ->
    FragList = genfrags(length(NeighboursListSize),ReplicationFactor),
	Pids = create(length(NeighboursListSize),[],NeighboursListSize,TransitionMatrix,Input,Function, FragList,ReplicationFactor, InputList,length(lists:flatten(FragList))),
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

create(0,Pids,NeighboursListSize,TransitionMatrix,Input,Function, FragList,ReplicationFactor,InputList,FragmentSize) -> Pids;
create(I,Pids,NeighboursListSize,TransitionMatrix,Input,Function, FragList,ReplicationFactor,InputList,FragmentSize)->
    Fragment = lists:nth(I, FragList),
    Nodeno =(length(NeighboursListSize)-I) +1,
    PartitionList = lists:split(lists:nth(Nodeno,NeighboursListSize),TransitionMatrix),
    NeighboursList = element(1, PartitionList),
	Myvalue = initthread(I,Input,Fragment,Function,InputList),
    Iterations = round(length(NeighboursListSize) * math:log(length(NeighboursListSize))) ,
    Minmaxelement = {0,length(Fragment)},
    Pid = spawn_link(fun() -> threadnodes(NeighboursListSize,NeighboursList,[],Myvalue, Fragment,Iterations,Minmaxelement,FragmentSize,getcurrentpid(I),ReplicationFactor) end),
    create(I-1,  (Pids ++ [Pid]), NeighboursListSize, element(2, PartitionList), Input,Function, FragList,ReplicationFactor,InputList,FragmentSize).

getcurrentpid(I)->
    if
        I==1 ->
            1;
        true -> 
            0
    end.

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

%Return [Median, lessthan],Fragment,[Gotmed]
computeNewParametersMedian(Myvalue,Value,Fragment) ->
    if
        (element(1,hd(Myvalue))==0) and (element(1,hd(Value)) ==0) ->
             [Value,Fragment];
        (element(1,hd(Myvalue)) /=0) and (element(1,hd(Value)) ==0)->  
            [Myvalue,Fragment];
        (element(1,hd(Myvalue)) ==0) and (element(1,hd(Value)) /=0) ->  
            Med = element(1,hd(Value)),
            Nolessthanelem =nolessthan(Med,Fragment),
            [[{Med,Nolessthanelem}],Fragment];
        true ->
            [[{element(1,hd(Value)),(element(2,hd(Myvalue))+element(2, hd(Value)))/2}],Fragment]
     end.

calculate(Function,Myvalue,Value,Fragment) ->
case Function of 
        max-> [[erlang:max(hd(Myvalue), hd(Value))],Fragment];
        min-> [[erlang:min(hd(Myvalue), hd(Value))],Fragment];
        mean->[[(hd(Myvalue) + hd(Value))/2],Fragment];
        median -> computeNewParametersMedian(Myvalue,Value,Fragment);
        meanfragments->[[(hd(Myvalue) + hd(Value))/2, (tl(Myvalue) + tl(Value))/(hd(Myvalue) + hd(Value))/2],Fragment];
        update -> updateFound:upFound(Myvalue, Value,Fragment) 
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
	return -> true;%io:format("~p : ~p Received from ~p :~p Computing ~p ~n", [hd(Printlist),hd(lists:nth(2,Printlist)),lists:nth(3,Printlist),hd(lists:nth(4,Printlist)), Function]);
	returnmsg -> true%io:format("~p : ~p Received from ~p :~p Reply Computing ~p ~n", [hd(Printlist),hd(lists:nth(2,Printlist)),lists:nth(3,Printlist),hd(lists:nth(4,Printlist)), Function])
end.
	
threadnodes(NeighboursListSize,NeighboursList,Pids,Myvalue,Fragment,Iterations,Minmaxelement,TotalElements,CurrentPid,ReplicationFactor) ->
	%p=getneighbours()
	receive
		%get the pids of all processes,
        {pid, Pidsmsg } ->
        	%io:format("I got pids ~p ~n",[self()]),
            random:seed(erlang:now()),
        	threadnodes(NeighboursListSize,NeighboursList,Pidsmsg,Myvalue,Fragment,Iterations,Minmaxelement,TotalElements,CurrentPid,ReplicationFactor);
        
        %Send Function	This function must be executed after every few minutes
        {send, Function} ->
            {I, P} = hd(NeighboursList),    
        	Pid=selectneighbours(NeighboursList, Pids,random:uniform(),P,1,I),
            Pid ! {Function, self(), Myvalue},
        	threadnodes(NeighboursListSize,NeighboursList,Pids,Myvalue,Fragment,Iterations-1,Minmaxelement,TotalElements,CurrentPid,ReplicationFactor);

        {yourturn, SenderPid, Function,SenderValue} ->
            io:format("~p I am your New Bully~n",[self()]),
            if
                CurrentPid == -1 ->
                    {I, P} = hd(NeighboursList),
                    Pid=selectneighbours(NeighboursList, Pids,random:uniform(),P,1,I),
                    NewCurrentPid = -1,
                    NewMyvalue = [{0,0}],
                    Pid ! {yourturn, self(),Function,SenderValue};
                CurrentPid == 0  ->
                    io:format("~p I am your New Bully~n",[self()]),
                    NewCurrentPid = 1,
                    NewMyvalue = SenderValue,
                    self() ! {convergence, Function}
            end,
            threadnodes(NeighboursListSize,NeighboursList,Pids,NewMyvalue,Fragment,Iterations-1,Minmaxelement,TotalElements,NewCurrentPid,ReplicationFactor);

        {convergence, Function} ->
            N = length(NeighboursListSize),
            %reset all values    
            ElemLessThanFrag = nolessthan(element(1,hd(Myvalue)),Fragment),%0
            %Divide by replication factor
            ElemLessThan = round((element(2,hd(Myvalue))*N)/ReplicationFactor),%0
            if
                (ElemLessThan > (round(TotalElements/2)-10)) and (ElemLessThan < (round(TotalElements/2)+10)) ->
                    %Stop here
                    io:format("Median is somewhere around ~p ~n",[element(1,hd(Myvalue))]);
                true ->
                    if
                        ElemLessThan < round(TotalElements/2) ->
                            NewMinmaxelement = {ElemLessThanFrag,element(2,Minmaxelement)};
                            %io:format("I am ~p Converged: ~p New fragment: ~p ~n",[self(),(element(2,hd(Myvalue))*N)/ReplicationFactor,NewMinmaxelement ]);
                        ElemLessThan > round(TotalElements/2) ->
                            NewMinmaxelement = {element(1,Minmaxelement),ElemLessThanFrag}
                            %io:format("I am ~p Converged: ~p New fragment: ~p ~n",[self(),(element(2,hd(Myvalue))*N)/ReplicationFactor,NewMinmaxelement])
                    end,
                    X = element(1,NewMinmaxelement),
                    Y = element(2,NewMinmaxelement),
                    if
                        CurrentPid ==1 ->
                            %it is first node
                            if
                                (Y-X) < 2 ->
                                    %select Neighbour at random and send yourturn message to it
                                    %Here I am selecting a node randomly, But this will not work in any topology
                                    %Here for Complete graph it will work as all nodes are connected to every other node
                                    %For others we can keep track of children and then do it.
                                    {I, P} = hd(NeighboursList),
                                    Pid=selectneighbours(NeighboursList, Pids,random:uniform(),P,1,I),
                                    NewCurrentPid = -1,
                                    NewMyvalue = [{0,0}],
                                    Pid ! {yourturn, self(),Function,Myvalue};
                                true ->
                                    %Expression Below gives smaller list which can contain median
                                    %sort list and then split using X and split using Y and then find its median This becomes new value for
                                    %first node
                                    MedianList = element(1,lists:split(Y-X-1,element(2,lists:split(X+1,lists:keysort(2,Fragment))))),
                                    NewCurrentPid = CurrentPid,
                                    Med = lists:nth(round((length(MedianList) / 2)), MedianList),
                                    NewMyvalue = [{element(2,Med),nolessthan(element(2,Med),Fragment)}],
                                    io:format("~p New Gossip Value ~p ~n",[self(),hd(NewMyvalue)])
                            end;
                        true ->
                            %Not First Node
                            NewMyvalue = [{0,0}],
                            NewCurrentPid = CurrentPid
                    end,
                    io:format("~p Value ~p less than ~p New Minmaxelement: ~p ~n",[self(),element(1,hd(Myvalue)),(element(2,hd(Myvalue))*N)/ReplicationFactor,NewMinmaxelement ]),
                    NewIterations = round(length(NeighboursListSize) * math:log(length(NeighboursListSize))),
                    threadnodes(NeighboursListSize,NeighboursList,Pids,NewMyvalue,Fragment,NewIterations,NewMinmaxelement,TotalElements,NewCurrentPid,ReplicationFactor)
            end;
            
        %Recieve Function from Process Pid with his value
        {Function, Pid, Value } ->
        	Pid ! { returnmsg, Function, self(), Myvalue },
        	printmsg(Function, return, [self(), Myvalue, Pid, Value]),
            NewParameters = calculate( Function, Myvalue,Value,Fragment),
            threadnodes(NeighboursListSize,NeighboursList,Pids,lists:nth(1,NewParameters) ,lists:nth(2,NewParameters),Iterations,Minmaxelement,TotalElements,CurrentPid,ReplicationFactor);

        %Reply Recieve Function from Process Pid with his value	
        {returnmsg, Function, Pid, Value } ->
            printmsg(Function, returnmsg, [self(),Myvalue,Pid,Value]),
            NewParameters = calculate( Function, Myvalue,Value,Fragment),
            threadnodes(NeighboursListSize,NeighboursList,Pids, lists:nth(1,NewParameters),lists:nth(2,NewParameters),Iterations,Minmaxelement,TotalElements,CurrentPid,ReplicationFactor);
        
        {tick, Function}->
        timer:send_after(100, {tick, Function}),
            if
                Iterations /= 0 ->
                    self() ! {send,Function},
                    threadnodes(NeighboursListSize,NeighboursList,Pids,Myvalue,Fragment,Iterations,Minmaxelement,TotalElements,CurrentPid,ReplicationFactor);
                Iterations == -1 ->
                    threadnodes(NeighboursListSize,NeighboursList,Pids,Myvalue,Fragment,-1,Minmaxelement,TotalElements,CurrentPid,ReplicationFactor);
                true -> 
                    %This Send after timming corresponds to maximum time sqew of all nodes.
                    timer:send_after(50000, {convergence, Function}),
                    threadnodes(NeighboursListSize,NeighboursList,Pids,Myvalue,Fragment,-1,Minmaxelement,TotalElements,CurrentPid,ReplicationFactor)
            end
            
    end.
