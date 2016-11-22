
c(tablet_server).
c(client).
c(masterserver).


Tablet1 = tablet_server:start_server().
Tablet2 = tablet_server:start_server().

Master = masterserver:start(master_registered_name).

Client = client:start(client_name, master_registered_name, node()).

Master ! {add_tablet, Tablet1}.
Master ! {add_tablet, Tablet2}.
Master ! {update_clients}.

Input = [{"Hello", "World"}, {"Hello2", "World2"}, {"Hell3", "Worl3"}].

% Add several rows
lists:map(fun({Key, Value}) -> Client ! {add_row, Key, Value} end, Input).

% Client ! {add_row, "Hello", "World"}.

% Tablet1 ! {addActiveRow, "Hello", "World"}.

This = self().

Client ! {queryR, fun(Key, Value) ->
					This ! {got_row, Key, Value}, ok
				  end }.

% Recursion lol...
Loop = fun(F) ->
	receive {got_row, Key, Value} ->
		io:format("Row : ~w => ~w", [Key, Value])
	end,
	F(F) end.

Loop(Loop).
