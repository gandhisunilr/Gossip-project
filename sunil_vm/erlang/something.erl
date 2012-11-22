-module(something).
-compile(export_all).
-import(matrix).

something(FileName) ->
    {ok, Device} = file:open(FileName, [read]),
    get_all_lines(1,Device, []).

get_all_lines(I,Device, Accum) ->
    case io:fread(Device, "","~f") of
    	eof -> file:close(Device), Accum;
    	{ok, [N]} -> 
            get_all_lines(I+1,Device, Accum ++ [{I,N}])
    end.