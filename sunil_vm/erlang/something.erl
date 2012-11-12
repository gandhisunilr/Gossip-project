-module(something).
-export([something/0]).
-import(matrix).

something()->
	matrix:new(3,3,fun (Column, Row, Columns, _) ->                      
	Columns * (Row - 1) + Column
	end).