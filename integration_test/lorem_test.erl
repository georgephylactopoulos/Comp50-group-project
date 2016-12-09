
M = master_server:find_master(master@localhost, master).

{ok, Text} = file:read_file("integration_test/lorem.txt").
Words = string:tokens(binary_to_list(Text), " ").
% Words = string:tokens("Hello world", " ").

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

io:format("Start load entire text ~n").

Fun(Fun, Words, 1).

io:format("End load entire text ~n").

io:format("Count the number of instances of 'lorem' ~n").

Instances1 = client:filter(M, fun({Key, Value}) -> Value == "lorem" end).

length(Instances1).

io:format("Sleep for 3 seconds, kill the first two tablets, and then Sleep for 3 seconds").

timer:sleep(1000 * 3).

[T1 | [T2 | _]] = gen_server:call(M, {get_tablets}).

exit(T1, some_reason).
exit(T2, some_reason).

timer:sleep(1000 * 3).

gen_server:call(M, {get_tablets}).


io:format("Count the number of instances of 'lorem' ~n").

Instances2 = client:filter(M, fun({Key, Value}) -> Value == "lorem" end).

length(Instances2).

