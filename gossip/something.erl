-module(something).
-compile(export_all).
-import(matrix).

something(FileName) ->
    {ok, Device} = file:open(FileName, [read]),
    get_all_lines(Device, []).

get_all_lines(Device, Accum) ->
	Tuple = io:fread(Device, "","~d,~f "),
    case Tuple of
    	eof -> file:close(Device), Accum;
    	{ok, [I, P]} -> 
            get_all_lines(Device, Accum ++ [{I,P}])
    end.