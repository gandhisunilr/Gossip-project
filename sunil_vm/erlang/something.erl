-module(something).
-compile(export_all).
-import(matrix).

something()->
	Pids = create(5,[]),
	Pids.

create(0,Pids) -> Pids;
create(I,Pids)->
	Pid = spawn_link(fun() -> threadnodes(print,I) end),
	create(I-1,  (Pids ++ [Pid]) ).

threadnodes(Action,TransitionMatrix) ->
	io:format("~p~n", [TransitionMatrix]).