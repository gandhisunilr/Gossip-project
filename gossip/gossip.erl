-module(gossip).
-import(matrix).
-import(lister).
-import(updateFound).
-import(fragreader, [genfrags/1]).
-import (nolessthan,[nolessthan/2]).
-compile(export_all).

start(Function,Input,InputList)->
	%P = generate_topology()
	P=matrix:new(10,10,fun (Column, Row, Columns, _) ->                      
	Columns * (Row - 1) + Column
	end),
	gossip(Function,P,Input,InputList).

gossip(Function,TransitionMatrix,Input,InputList) ->
    FragList = genfrags(length(TransitionMatrix)),
	Pids = create(length(TransitionMatrix),[],TransitionMatrix,Input,Function, FragList,InputList),
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

create(0,Pids,TransitionMatrix,Input,Function, FragList,InputList) -> Pids;
create(I,Pids,TransitionMatrix,Input,Function, FragList,InputList)->
    Fragment = lists:nth(I, FragList),
	Myvalue = initthread(I,Input,Fragment,Function,InputList),
    Memory = getmemory(I,Function),
    Pid = spawn_link(fun() -> threadnodes(TransitionMatrix,[],Myvalue, Fragment) end),
	create(I-1,  (Pids ++ [Pid]), TransitionMatrix, Input,Function, FragList,InputList).

getmemory(I,Function) ->
    case Function of 
        median -> 
            if
                I ==1 ->[1];
                true -> [0]
            end;
        X -> []
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
        %It dosen't execute above statement means that myvalue and value is not zero
        %if it gets value and gotmed =0 then MyValue 
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
	return -> io:format("~p : ~p Received from ~p :~p Computing ~p ~n", [hd(Printlist),hd(lists:nth(2,Printlist)),lists:nth(3,Printlist),hd(lists:nth(4,Printlist)), Function]);
	returnmsg -> io:format("~p : ~p Received from ~p :~p Reply Computing ~p ~n", [hd(Printlist),hd(lists:nth(2,Printlist)),lists:nth(3,Printlist),hd(lists:nth(4,Printlist)), Function])
end.
	

threadnodes(TransitionMatrix,Pids,Myvalue,Fragment) ->
	%getneighbours()
	receive
		%get the pids of all processes,
        {pid, Pidsmsg } ->
        	io:format("I got pids ~p ~n",[self()]),
        	threadnodes(TransitionMatrix,Pidsmsg,Myvalue,Fragment);
        
        %Send Function	This function must be executed after every few minutes
        {send, Function} ->
        	Pid=selectneighbours(TransitionMatrix, Pids, self()),
        	Pid ! {Function, self(), Myvalue},
        	threadnodes(TransitionMatrix,Pids,Myvalue,Fragment);

        %Recieve Function from Process Pid with his value
        {Function, Pid, Value } ->
        	Pid ! { returnmsg, Function, self(), Myvalue },
        	printmsg(Function, return, [self(), Myvalue, Pid, Value]),
            NewParameters = calculate( Function, Myvalue,Value,Fragment),
            threadnodes(TransitionMatrix,Pids,lists:nth(1,NewParameters) ,lists:nth(2,NewParameters));

        %Reply Recieve Function from Process Pid with his value	
        {returnmsg, Function, Pid, Value } ->
            printmsg(Function, returnmsg, [self(),Myvalue,Pid,Value]),
            NewParameters = calculate( Function, Myvalue,Value,Fragment),
            threadnodes(TransitionMatrix,Pids, lists:nth(1,NewParameters),lists:nth(2,NewParameters));
            
        {tick, Function}->
       		self() ! {send,Function},
            timer:send_after(1000, {tick, Function}),
            threadnodes(TransitionMatrix,Pids,Myvalue,Fragment)
    end.
