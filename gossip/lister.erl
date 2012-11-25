%Finds the maximum, minimum or sum based on the second element of the list. 
%getValue([{2, 2}, {3, 3}, {1, 4}], max) => [4]
-module(lister).
-compile(export_all).

getValue(I, [], Op, InputList) -> empty;

getValue(I, List, Op, InputList) ->
    case Op of
        update -> 
            if
                I == 1 -> [hd(InputList)];
                true -> [{0, 0}]
            end;
        median -> 
            if
                I == 1 -> summarize(List,[],median);
                true -> [0, 0]
            end;   
        X-> summarize(List, [], Op)
    end.

summarize([], L, Op) -> 
    case Op of
        max -> [lists:max(L)];
        min -> [lists:min(L)];
        median -> [lists:nth(round((length(L) / 2)), lists:sort(L)), round(length(L)/2)-1];
        mean -> [erlang:length(L), lists:sum(L)]
    end;
    
    
summarize([H|T], L, Op) -> 
    summarize(T, [split(H)|L], Op).

split({X, Y}) -> Y.

retriever(Myvalue, Pids, Pid) ->
    case lists:nth(length(Pids), Pids) == Pid of
        true -> [hd(Myvalue)|[Pid]]; 
        false -> [{0,0}]
    end.
