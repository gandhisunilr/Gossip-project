-module(functions).
-compile(export_all).

head([H|_]) -> H.

second([_,X|_]) -> X.

same(X, X) ->
    true;

same(_,_) ->
    false;

wrong_age(X) when X < 16; X > 104 ->
    true;
wrong_age(_) ->
    false.

