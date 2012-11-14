Erlang Essentials
=================

*. Compiling the Code

$ erlc flags filename.erl

1> c(filename).

2> compile:file(filename, [debug_info, export_all]).

*. List Comprehension

NewList = [Expression || GeneratorExp1, GeneratorExp2, ..., GeneratorExpN, Condition1, Condition2, ... ConditionM]

* Sending and recieving messages between processes

receive
Pattern1 when Guard1 -> Expr1;
Pattern2 when Guard2 -> Expr2;
Pattern3 -> Expr3
end

* Spawning a thread

3> spawn(fun() -> io:format("~p~n", [2 + 2]) end).

4> F = spawn(filename, fun_name, []).

* Timeout Constructs

receive
Match -> Expression1
after Delay ->
Expression2
end.

sleep(T) ->
receive
after T -> ok
end.

In the case you do need to work with a priority in your messages and can't use such a catch-all clause, a smarter way to do it would be to implement a min-heap or use the gb_trees module and dump every received message in it (make sure to put the priority number first in the key so it gets used for sorting the messages). Then you can just search for the smallest or largest element in the data structure according to your needs.


