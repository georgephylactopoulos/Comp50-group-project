-module(client).
-export([add_row/3,send_add_row_message/3,delete_row/2,
	update_row/3,get_row/2,filter/2]).

% Function asks the master which tablets are currently in the
% cluster and the send_add_row_message() helper function.
add_row(MasterServerPid, Key, Value) ->
	Tablets = gen_server:call(MasterServerPid, {get_tablets}),
	send_add_row_message(Tablets, Key, Value).

% Helper function for add_row(). Function selects
% a tablet at random and sends it an add_row command.
% Random selection should provide more even load 
% balancing.
send_add_row_message([], _Key, _Value) -> no_tablets;
send_add_row_message(Tablets, Key, Value) ->
	TabletListLength = length(Tablets),
	Index = rand:uniform(TabletListLength),
	Tablet = lists:nth(Index, Tablets),
	gen_server:cast(Tablet, {add_row, Key, Value}).

% Function asks the master which tablets are currently in the
% cluster and then sends them delete_row commands in parallel.
% There should be at most one tablet with an active row that 
% corresponds to this key. If that active row is found it will
% be deleted.
delete_row(MasterServerPid, Key) ->
    Tablets = gen_server:call(MasterServerPid, {get_tablets}),
	util:parallel_map(fun(T) ->
		gen_server:cast(T, {delete_row, Key})
	end, Tablets).

% Function asks the master which tablets are currently in the
% cluster and then sends them update_row commands in parallel.
% There should be at most one tablet with an active row that 
% corresponds to this key. If that active row is found it will
% be updated.
update_row(MasterServerPid, Key, Value) ->
	Tablets = gen_server:call(MasterServerPid, {get_tablets}),
	util:parallel_map(fun(T) ->
		gen_server:cast(T, {update_row, Key, Value})
	end, Tablets).

% Function asks the master which tablets are currently in the
% cluster and then get_row calls in parallel.
% There should be at most one tablet with an active row that 
% corresponds to this key. If that active row is found it will
% be returned. If no match is found, the function returns no_match
get_row(MasterServerPid, Key) ->
	Tablets = gen_server:call(MasterServerPid, {get_tablets}),
	Results = util:parallel_map(fun(T) ->
		Result = gen_server:call(T, {get_row, Key}),
		case Result of
			no_match -> [];
			_ -> [Result]
		end
	end, Tablets),
	case lists:merge(Results) of
		[First | _] -> First;
		_ -> no_match
	end.

% Function asks the master which tablets are currently in the
% cluster and then sends then makes parallel filter calls.
% It then merges the results and returns them.
filter(Master, Function) ->
	Tablets = gen_server:call(Master, {get_tablets}),
	Results = util:parallel_map(fun(T) ->
		gen_server:call(T, {filter, Function})
	end, Tablets),
	lists:merge(Results).
