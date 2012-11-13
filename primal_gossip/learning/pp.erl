-module(pp).

-compile(export_all).

ping(0, PID) ->
    PID ! finished,
    io:format("ping finished~n", []);
   

ping(N, PID) ->
    PID ! {self(), ping},
    receive 
        pong -> 
            io:format("Ping received pong~n", [])
    end,
    ping(N-1, PID).

pong() ->
    receive
        finished ->
            io:format("Pong finished", []);
        {PID, ping} -> 
            io:format("Pong received ping~n", []),
            PID ! pong,
            pong()
    end.

start() ->
    PID = spawn(pp, pong, []),
    spawn(pp, ping, [3, PID]).
