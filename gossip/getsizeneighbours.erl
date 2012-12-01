-module(getsizeneighbours).
-compile(export_all).
-import(matrix).

getsizeneighbours(FileName) ->
    {ok, Device} = file:open(FileName, [read]),
    get_all_lines(Device, []).

get_all_lines(Device, Accum) ->
	Tuple = io:fread(Device, "","~d"),
    case Tuple of
    	eof -> file:close(Device), Accum;
    	{ok, [N]} -> 
            get_all_lines(Device, Accum ++ [N])
    end.