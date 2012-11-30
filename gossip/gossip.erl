-module(gossip).
-import(matrix).
-import(lister).
-import(updateFound).
-import(fragreader, [genfrags/2]).
-import (nolessthan,[nolessthan/2]).
-compile(export_all).

start(Function,Input,ReplicationFactor,InputList)->
	%P = generate_topology()
	P=matrix:new(10,10,fun (Column, Row, Columns, _) ->                      
	Columns * (Row - 1) + Column
	end),
	gossip(Function,P,Input,ReplicationFactor,InputList).

gossip(Function,TransitionMatrix,Input,ReplicationFactor, InputList) ->
    FragList = genfrags(length(TransitionMatrix),ReplicationFactor),
	Pids = create(length(TransitionMatrix),[],TransitionMatrix,Input,Function, FragList,ReplicationFactor, InputList),
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
create(I,Pids,TransitionMatrix,Input,Function, FragList,ReplicationFactor,InputList)->
    Fragment = lists:nth(I, FragList),
	Myvalue = initthread(I,Input,Fragment,Function,InputList),
    Iterations = length(TransitionMatrix) * length(TransitionMatrix),
    Minmaxelement = {0,length(Fragment)},
    Pid = spawn_link(fun() -> threadnodes(TransitionMatrix,[],Myvalue, Fragment,Iterations,Minmaxelement,999,getcurrentpid(I),ReplicationFactor) end),
	create(I-1,  (Pids ++ [Pid]), TransitionMatrix, Input,Function, FragList,ReplicationFactor,InputList).

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

selectneighbours(TransitionMatrix, Pids, Pid) ->
	lists:nth(random:uniform(length(TransitionMatrix)), Pids).

printmsg(Function,Type,Printlist)->
case Type of
	return -> true;%io:format("~p : ~p Received from ~p :~p Computing ~p ~n", [hd(Printlist),hd(lists:nth(2,Printlist)),lists:nth(3,Printlist),hd(lists:nth(4,Printlist)), Function]);
	returnmsg -> true%io:format("~p : ~p Received from ~p :~p Reply Computing ~p ~n", [hd(Printlist),hd(lists:nth(2,Printlist)),lists:nth(3,Printlist),hd(lists:nth(4,Printlist)), Function])
end.
	

threadnodes(TransitionMatrix,Pids,Myvalue,Fragment,Iterations,Minmaxelement,TotalElements,CurrentPid,ReplicationFactor) ->
	%getneighbours()
	receive
		%get the pids of all processes,
        {pid, Pidsmsg } ->
        	%io:format("I got pids ~p ~n",[self()]),
            NewIterations = length(TransitionMatrix) * length(TransitionMatrix),
        	threadnodes(TransitionMatrix,Pidsmsg,Myvalue,Fragment,NewIterations,Minmaxelement,TotalElements,CurrentPid,ReplicationFactor);
        
        %Send Function	This function must be executed after every few minutes
        {send, Function} ->
        	Pid=selectneighbours(TransitionMatrix, Pids, self()),
        	Pid ! {Function, self(), Myvalue},
        	threadnodes(TransitionMatrix,Pids,Myvalue,Fragment,Iterations-1,Minmaxelement,TotalElements,CurrentPid,ReplicationFactor);

        {yourturn, SenderPid, Function} ->
            io:format("~p I am your New Bully~n",[self()]),
            if
                CurrentPid == -1 ->
                    SenderPid ! {sorry,Function},
                    NewCurrentPid = CurrentPid;
                CurrentPid == 0  ->
                    io:format("~p I am your New Bully~n",[self()]),
                    NewCurrentPid = 1,
                    self() ! {convergence, Function}
            end,
            threadnodes(TransitionMatrix,Pids,Myvalue,Fragment,Iterations-1,Minmaxelement,TotalElements,NewCurrentPid,ReplicationFactor);            

        {sorry,Function} -> 
            self() ! {convergence, Function};

        {convergence, Function} ->
            N = length(TransitionMatrix),
            %reset all values    
            ElemLessThanFrag = nolessthan(element(1,hd(Myvalue)),Fragment),
            %Divide by replication factor
            ElemLessThan = round((element(2,hd(Myvalue))*N)/ReplicationFactor),
            if
                (ElemLessThan > (round(TotalElements/2)-5)) and (ElemLessThan < (round(TotalElements/2)+5)) ->
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
                                    Pid=selectneighbours(TransitionMatrix, Pids, self()),
                                    NewCurrentPid = -1,
                                    NewMyvalue = [{0,0}],
                                    Pid ! {yourturn, self(),Function};
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
                    NewIterations = length(TransitionMatrix)*length(TransitionMatrix),
                    threadnodes(TransitionMatrix,Pids,NewMyvalue,Fragment,NewIterations,NewMinmaxelement,TotalElements,NewCurrentPid,ReplicationFactor)
            end;
            
        %Recieve Function from Process Pid with his value
        {Function, Pid, Value } ->
        	Pid ! { returnmsg, Function, self(), Myvalue },
        	printmsg(Function, return, [self(), Myvalue, Pid, Value]),
            NewParameters = calculate( Function, Myvalue,Value,Fragment),
            %TODO: Fix this function and returnmsg pass Minmaxelement to calculate (Question : will it return it?)
            threadnodes(TransitionMatrix,Pids,lists:nth(1,NewParameters) ,lists:nth(2,NewParameters),Iterations,Minmaxelement,TotalElements,CurrentPid,ReplicationFactor);

        %Reply Recieve Function from Process Pid with his value	
        {returnmsg, Function, Pid, Value } ->
            printmsg(Function, returnmsg, [self(),Myvalue,Pid,Value]),
            NewParameters = calculate( Function, Myvalue,Value,Fragment),
            threadnodes(TransitionMatrix,Pids, lists:nth(1,NewParameters),lists:nth(2,NewParameters),Iterations,Minmaxelement,TotalElements,CurrentPid,ReplicationFactor);
        
        {tick, Function}->
        timer:send_after(100, {tick, Function}),
            if
                Iterations /= 0 ->
                    self() ! {send,Function},
                    threadnodes(TransitionMatrix,Pids,Myvalue,Fragment,Iterations,Minmaxelement,TotalElements,CurrentPid,ReplicationFactor);
                Iterations == -1 ->
                    threadnodes(TransitionMatrix,Pids,Myvalue,Fragment,-1,Minmaxelement,TotalElements,CurrentPid,ReplicationFactor);
                true -> 
                    %This Send after timming corresponds to maximum time sqew of all nodes.
                    timer:send_after(10000, {convergence, Function}),
                    threadnodes(TransitionMatrix,Pids,Myvalue,Fragment,-1,Minmaxelement,TotalElements,CurrentPid,ReplicationFactor)
            end
            
    end.
