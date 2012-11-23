-module(something).
-compile(export_all).
-import(matrix).

something(FileName) ->
    {ok, Device} = file:open(FileName, [read]),
    P = get_all_lines(Device, [], 1),
    fragmentize(P, 100, []).

get_all_lines(Device, Accum, Index) ->
    case io:fread(Device, "","~f") of
    	eof -> file:close(Device), Accum;
    	{ok, [N]} -> 
            get_all_lines(Device, Accum ++ [{Index, N}], Index+1)
    end.

add3(P, N, Value, F, I) when I == 0 ->
    fragmentize(P, N-1, F); %return to fragmentize

add3(P, N, Value, F, I) when I > 0 ->            
    add3(P, N, Value, [ [Value|lists:nth(random:uniform(length(F)), F)] | lists:delete(lists:nth(random:uniform(length(F)), F), F)], I-1).

fragmentize(P, N, F) when length(F) < N -> 
    fragmentize(P, N, F ++ [[lists:nth(random:uniform(length(P)), P)]]);

fragmentize(P, N, F) when N > 0 ->
    add3(P, N, lists:nth(random:uniform(length(P)), P), F, 3);

fragmentize(P, N, F) when N == 0 ->
    F.

