-module(client).
-export([add_row/3,send_add_row_message/3,delete_row/2,
	update_row/3,get_row/2,filter/2]).

send_add_row_message(Tablets,Key,Value) ->
	TabletListLength = length(Tablets),
	Index = rand:uniform(TabletListLength),
	Tablet = lists:nth(Index,Tablets),
	gen_server:cast(Tablet,{add_row, Key,Value}).

add_row(MasterServerPid,Key,Value) ->
	Tablets = gen_server:call(MasterServerPid,{get_tablets}),
	send_add_row_message(Tablet, Key, Value).

delete_row(MasterServerPid,Key) ->
    Tablets = gen_server:call(MasterServerPid,{get_tablets}),
	util:parallel_map(fun(T) ->
		gen_server:cast(T, {delete_row, Key})
	end, Tablets).

update_row(MasterServerPid,Key,Value) ->
	Tablets = gen_server:call(MasterServerPid,{get_tablets}),
	util:parallel_map(fun(T) ->
		gen_server:cast(T, {update_row, Key, Value})
	end, Tablets).

get_row(MasterServerPid, Key) ->
	Tablets = gen_server:call(MasterServerPid,{get_tablets}),
	util:parallel_map(fun(T) ->
		Results = gen_server:call(T, {update_row, Key, Value}),
		case Results of
			{no_match} -> [];
			_ -> [Results]
		end
	end, Tablets),
	case lists:merge(Results) of
		[First | _] -> First;
		_ -> no_match
	end.

filter(Master, Function) ->
	Tablets = gen_server:call(MasterServerPid,{get_tablets}),
	Resuls = util:parallel_map(fun(T)) ->
		Result = gen_server:call(T, {filter, Function})
	end, Tablets),
	lists:merge(Results).
