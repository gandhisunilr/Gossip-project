-module(something).
-compile(export_all).
-import(matrix).

something(Function,Myvalue, Value)->
    case Function of 
        max -> erlang:max(Myvalue,Value);
        min -> erlang:min(Myvalue,Value);
        mean -> (Myvalue + Value)/2
    end.