-module(something).
-compile(export_all).
-import(matrix).

something() ->
	Pid =spawn_link(fun() -> myprocess() end),
	Pid ! {tick, [1,2,3,4] }.

myprocess()->
    receive
    	{ tick, Pids } ->
    		% write code for doing things periodically
    		io:format("This is list Pids: ~p",[Pids])
		end.
