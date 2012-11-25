-module(updateFound).
-compile(export_all).

upFound(Myvalue, Value, Fragment) ->
    if Myvalue == {0, 0} ->
        {K, V} = Value;
        true -> {K, V} = Myvalue 
    end,
    case lists:keyfind(K, 1, Fragment) of
        false -> [[{K,V}], Fragment];
        X -> [[{K,V}], [{K, V}|lists:delete(X, Fragment)]]
    end.
    
    
            
