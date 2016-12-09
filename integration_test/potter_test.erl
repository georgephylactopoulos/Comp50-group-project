
M = master_server:find_master(master@localhost, master).

{ok, Text} = file:read_file("integration_test/potter.txt").
Words = string:tokens(binary_to_list(Text), " ").

Fun = fun(Fun, Words, I) ->
	case Words of
		[] -> ok;
		[First | Rest] ->
			case I rem 1000 of
				0 -> io:format("i: ~p ~n", [I]);
				_ -> ok
			end,
			client:add_row(M, I, First),
			Fun(Fun, Rest, I + 1)
	end
end.

io:format("Start load entire book ~n").

Fun(Fun, Words, 1).

io:format("End load entire book ~n").

io:format("Count the number of instances of 'magic' ~n").

Instances = client:filter(M, fun({Key, Value}) -> Value == "magic" end).

length(Instances).



