-module(filereader).
-compile(export_all).
-import(matrix).

readlines(FileName) ->
    {ok, Device} = file:open(FileName, [read]),
 	get_all_lines(Device, []).

get_all_lines(Device, Accum) ->
    case file:read_line(Device) of
    	eof -> 
    		file:close(Device), lists:reverse(Accum);
        {ok, Line} -> 
        	Str = re:replace(Line, "\\s+", "", [global,{return,list}]),
        	io:format("~p", [Str])
    end.

