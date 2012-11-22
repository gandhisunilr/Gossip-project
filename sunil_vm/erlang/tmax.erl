%Finds the maximum of the list based on the second element of the list. 
%lt_max([{2, 2}, {3, 3}, {1, 4}] => 4
-module(tmax).
-compile(export_all).


lt_max([]) -> empty;

lt_max([H|T]) -> lt_max([H|T], []). 

lt_max([], Max) -> lists:max(Max);

lt_max([H|T], Max) -> 
    lt_max(T, [split(H)|Max]).

split({X, Y}) -> Y.


    
