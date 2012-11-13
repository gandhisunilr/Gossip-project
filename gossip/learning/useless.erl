-module(useless).
-export([add/2, hello/0, greet_and_add_two/1]).
-import(io, [format/1]).
add(A, B) ->
    A + B.


%% Standard function for outputting text    
hello() ->
    format("Hello World~n").    
    
greet_and_add_two(X) ->
    hello(),
    add(X, 2).    
