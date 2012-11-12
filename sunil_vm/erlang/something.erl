-module(something).
-compile(export_all).
-import(matrix).

something() ->
	spawn_link(fun() -> myprocess() end),

myprocess()->
    receive
    	tick ->
    		% write code for doing things periodically
    		io:format("Got one"),
			timer:send_after(1000, tick)
		end,
	myprocess().

