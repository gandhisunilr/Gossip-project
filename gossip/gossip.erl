-module(gossip).
-import(matrix).
-import(lister).
-import(updateFound).
-import(fragreader, [genfrags/1]).
-compile(export_all).

start(Function,Input,InputList)->
	%P = generate_topology()
	P=matrix:new(100,100,fun (Column, Row, Columns, _) ->                      
	Columns * (Row - 1) + Column
	end),
	gossip(Function,P,Input,InputList).

gossip(Function,TransitionMatrix,Input,InputList) ->
    FragList = genfrags(length(TransitionMatrix)),
	Pids = create(length(TransitionMatrix),[],TransitionMatrix,Input,Function, FragList,InputList),
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

create(0,Pids,TransitionMatrix,Input,Function, FragList,InputList) -> Pids;
create(I,Pids,TransitionMatrix,Input,Function, FragList,InputList)->
    Fragment = lists:nth(I, FragList),
	Pid = spawn_link(fun() -> threadnodes(TransitionMatrix,[],initthread(I,Input,Fragment,Function,InputList), Fragment, 0) end),
	create(I-1,  (Pids ++ [Pid]), TransitionMatrix, Input,Function, FragList,InputList).

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


%            Tail = tl(hd(Result)),
%            Head = hd(hd(Result)),
%            {_, Y} = Head,
%            if Tail /= [], Y /= 0  ->
%                hd(tl(hd(Result))) ! {retrieve, Head};
             %   io:format("Result is ~p and ~p", [hd(Tail), Resut]);
%            true -> empty 
%            end,
%        Result    
%    end.

selectneighbours(TransitionMatrix, Pids, Pid) ->
	lists:nth(random:uniform(length(TransitionMatrix)), Pids).

printmsg(Function,Type,Printlist)->
case Type of
	return -> io:format("~p : ~p Received from ~p :~p Computing ~p ~n", [hd(Printlist),hd(lists:nth(2,Printlist)),lists:nth(3,Printlist),hd(lists:nth(4,Printlist)), Function]);
	returnmsg -> io:format("~p : ~p Received from ~p :~p Reply Computing ~p ~n", [hd(Printlist),hd(lists:nth(2,Printlist)),lists:nth(3,Printlist),hd(lists:nth(4,Printlist)), Function])
end.
	

threadnodes(TransitionMatrix,Pids,Myvalue,Fragment,Parent) ->
    %TODO: Do we need Myvalue as it can be calculated from Fragment?
	%getneighbours()
	receive
		%get the pids of all processes,
        {pid, Pidsmsg } ->
        %	io:format("I am ~p and my value, fragment are ~p | ~p~n ",[self(), Myvalue, Fragment]),
        % 	threadnodes(TransitionMatrix,Pidsmsg, lister:retriever(Myvalue, Pidsmsg, self()), Fragment);
        	threadnodes(TransitionMatrix,Pidsmsg, Myvalue, Fragment,Parent);
        
         {pid, Pidsmsg, retrieve} ->
       % 	io:format("Retrieve: I am ~p and my value, fragment are ~p | ~p~n ",[self(), Myvalue, Fragment]),
         	threadnodes(TransitionMatrix,Pidsmsg, lister:retriever(Myvalue, Pidsmsg, self()), Fragment, Parent);
        
        %Send Function	This function must be executed after every few minutes
        {send, Function} ->
        	Pid=selectneighbours(TransitionMatrix, Pids, self()),
        	Pid ! {Function, self(), Myvalue},
        	threadnodes(TransitionMatrix,Pids,Myvalue,Fragment,Parent);

        %Recieve Function from Process Pid with his value
        {Function, Pid, Value } ->
        	Pid ! { returnmsg, Function, self(), Myvalue },
        %	printmsg(Function, return, [self(), Myvalue, Pid, Value]),
            ValueList = calculate(Function, Myvalue, Value, Fragment, Pid, Parent),
        %    io:format("Result in Recieve ~p", [ValueList]),
            threadnodes(TransitionMatrix,Pids, lists:nth(1,ValueList),lists:nth(2,ValueList),lists:nth(3, ValueList));

        %Reply Recieve Function from Process Pid with his value	
        {returnmsg, Function, Pid, Value } ->
         %   printmsg(Function, returnmsg, [self(),Myvalue,Pid,Value]),
            ValueList = calculate(Function, Myvalue, Value, Fragment, Pid, Parent),
         %   io:format("Result in Returnmsg~p", [ValueList]),
            threadnodes(TransitionMatrix,Pids, lists:nth(1,ValueList),lists:nth(2,ValueList),lists:nth(3, ValueList));

        {retrieve, Result} ->
            io:format("~p retrieve ~p ",[self(), hd(hd(Result))]),
            if self() /= tl(hd(Result)), Parent /= 0 -> Parent ! {retrieve, Result};
            true -> io:format("###Node 1 ~p Parent ~p retrieve ~p ~n###",[self(), Parent, hd(hd(Result))])
            end;

        {tick, Function}->
       		self() ! {send,Function},
            timer:send_after(1000, {tick, Function}),
            threadnodes(TransitionMatrix,Pids,Myvalue,Fragment,Parent)
    end.
