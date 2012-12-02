%% 
% 
% Reads random numbers stored in a file and generates a list 
% of fragments with length equal to number of nodes.
% 
% Factor parameter determines how many a value would be replicated
% if given Factor = 3, it means every Value would be replicated 
% across 3 fragments.
%
% Fragments of the form: [{I1, V1},{I2, V2},{I3, V3}........]
% where I denotes the Index value of the fragment starting from 
% 1 and till the number of random files in the file and Value denotes
% the random number read from the file.
%
% Working principle: Fragments are created initially by assigning them a 
% randomly chosen Value. Once N(number of nodes) has been created, each Value 
% is taken and added to a randomly selected fragment if it doesn't already
% have that Value.
%
% Output = List of Fragments with length(Ouput) = N
%%

-module(fragreader).
-compile(export_all).

genfrags(Nodes, Factor) ->
    {ok, Device} = file:open(randnofile, [read]),
        Parts = get_all_lines(Device, [], 1),
            fragmentize(Parts, length(Parts),[], Nodes, Factor).

get_all_lines(Device, Accum, Index) ->
	case io:fread(Device, "","~f") of
		eof -> file:close(Device), Accum;
        	{ok, [N]} ->
             	get_all_lines(Device, Accum ++ [{Index, N}], Index+1)
	end.

fragmentize(Parts, Len, Fragments, Nodes, Factor) when length(Fragments) < Nodes ->
    %Initial Step: Creating N Fragments
	fragmentize(Parts, Len, Fragments ++ [[lists:nth(random:uniform(length(Parts)), Parts)]], Nodes, Factor);

fragmentize(Parts, Len, Fragments, Nodes, Factor) when Len > 0 ->
    %Selecting a Value from Parts and calling addFactor
    Index = Factor,
	addFactor(Parts, Len, lists:nth(Len, Parts), Fragments, Index, Nodes, Factor);

fragmentize(Parts, Len, Fragments, Nodes, Factor) when Len == 0 ->
	Fragments.

addFactor(Parts, Len, Value, Fragments, Index, Nodes, Factor) when Index == 0 ->
    %Done adding Factor number of times, calling fragmentize to get the next Value to be distributed
	fragmentize(Parts, Len-1, Fragments, Nodes-1, Factor); %return to fragmentize

addFactor(Parts, Len, Value, Fragments, Index, Nodes, Factor) when Index > 0 ->
    %Distributes a Part among 'Factor' number of random fragments
    Frag = lists:nth(random:uniform(length(Fragments)), Fragments),
    {K, V} = Value,
    Found = lists:keyfind(K, 1, Frag),
    if 
        Found == false -> Temp= lists:delete(Frag, Fragments),
        addFactor(Parts, Len, Value, [[Value | Frag]|Temp], Index-1, Nodes, Factor);
        true -> addFactor(Parts, Len, Value, Fragments, Index, Nodes, Factor)
    end.

