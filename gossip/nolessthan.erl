-module(nolessthan).
-compile(export_all).

nolessthan(Value,Fragment) ->
    SortedList = lists:keysort(2,Fragment),
    noofelements(Value, SortedList,0).

noofelements(Value, SortedList, Noofelem) ->
    if
        (element(2,hd(SortedList)) < Value) ->
            noofelements(Value, tl(SortedList),Noofelem+1);
        true ->
            Noofelem
    end.