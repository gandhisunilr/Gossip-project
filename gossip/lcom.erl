%Finds the maximum, minimum or sum based on the second element of the list. 
%lcom([{2, 2}, {3, 3}, {1, 4}], max) => 4
-module(lcom).
-compile(export_all).

lcom([], Op) -> empty;

lcom([H|T], Op) -> lcom([H|T], [], Op). 

lcom([], L, Op) -> 
    case Op of
        max -> lists:max(L);
        min -> lists:min(L);
        sum -> lists:sum(L)
    end;
    
lcom([H|T], L, Op) -> 
    lcom(T, [split(H)|L], Op).

split({X, Y}) -> Y.


    
