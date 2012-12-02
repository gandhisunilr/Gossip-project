-module(updateFound).
-compile(export_all).

%Computation for Update and Retrieve Functions
upFound(Myvalue, Value, Fragment, Function) ->
    Mytuple = hd(Myvalue), %Myvalue = []
    Tuple = hd(Value),
    if Mytuple == {0, 0} ->
        {K, V} = Tuple;
        true -> {K, V} = Mytuple 
    end,
    Found = lists:keyfind(K, 1, Fragment),
    case Function of
        update ->
            if Found == false ->
                [[{K,V}], Fragment];
            true ->    
                Temp = [[{K,V}], [{K, V}|lists:delete(Found, Fragment)]],
                io:format("Updated Fragment, Previous ~p -> Now ~p~n", [Fragment, Temp]),
                Temp
            end;    
        retrieve ->
            io:format("Myvalue ~p, Value ~p", [Myvalue, Value]),
            if tl(Myvalue) /= [] -> %Checking
                Pid = tl(Myvalue);
            true -> Pid = tl(Value)
            end,
            if Found == false ->
                [[{K,V} | Pid], Fragment];
            true ->
%                io:format("Retrieving value from Fragment ~p, the value is ~p~n", [Fragment, Found]),
                [[Found | Pid], Fragment]
            end
    end.
                
