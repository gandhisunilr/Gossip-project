
%References
%http://erlang.org/pipermail/erlang-questions/2010-October/054174.html

-module(topgen).
-import(math).
-compile(export_all).


grapher(Size) ->
	Graph = digraph:new(),
	V = generate_coordinates(Size),
	GV = [digraph:add_vertex(Graph, X) || X<- V],
	check_edges(Graph, GV, length(GV)).

check_edges(G, GV, 0) -> G;

check_edges(G, GV, Len) ->
	V1 = lists:nth(Len, GV),
	Neighbours = find_neighbours(V1, GV, length(GV), []),
%	io:format("~p", Neighbours),
	[digraph:add_edge(G, V1, X) || X <- Neighbours],
	check_edges(G, GV, Len-1).

find_neighbours(Value, GV, 0, Neighbours) ->
	if Neighbours /= [] -> Neighbours;
		true -> io:format("Neighbours empty") 
	end;

find_neighbours(Value, GV, Index, Neighbours) ->
	V2 = lists:nth(Index, GV),
	{X, Y} = V2,
	{X0, Y0} = Value,
	Flag = is_neighbour(calculate_distance(X0,Y0,X,Y)),
	if Flag /= false -> Temp = [V2 | Neighbours],
		find_neighbours(Value, GV, Index-1, Temp);
		true -> find_neighbours(Value, GV, Index-1, Neighbours)
		end.	

is_neighbour(Distance) -> 
	if Distance >= 0.1 -> false; 
		true -> true
	end.
	
generate_coordinates(N) ->
	L = lists:seq(1, N),
	[{X0, Y0} | Points] = [{random:uniform(), random:uniform()} || _<- L].

calculate_distance(X0, Y0, X, Y) ->
	math:sqrt((X - X0) * (X - X0) + (Y - Y0) * (Y - Y0)).