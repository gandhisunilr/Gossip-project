%Finds the maximum, minimum or sum based on the second element of the list. 
%summarize([{2, 2}, {3, 3}, {1, 4}], max) => [4]
-module(lister).
-compile(export_all).

summarize([], Op) -> empty;

summarize([H|T], Op) -> summarize([H|T], [], Op). 

summarize([], L, Op) -> 
    case Op of
        max -> [lists:max(L)];
        min -> [lists:min(L)];
        sum -> [erlang:length(L), lists:sum(L)]
    end;
    
summarize([H|T], L, Op) -> 
    summarize(T, [split(H)|L], Op).

split({X, Y}) -> Y.


    
