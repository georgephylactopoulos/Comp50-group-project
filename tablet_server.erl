
-module(tablet_server).

-export([start/0, stop/1]).
-export([init/1, handle_call/3, handle_cast/2]).

% TODO this needs a unique name (because of the dets file names)
start() ->
	{ok, ActiveTable} = dets:open_file(active_table, []),
	{ok, InactiveTable} = dets:open_file(inactive_table_disk, []),
	gen_server:start(tablet_server, {ActiveTable,  InactiveTable}, []).

stop(Pid) ->
	gen_server:stop(Pid).


init(Args) -> {ok, Args}.


handle_cast(Request, State) ->
	{ActiveTable, InactiveTable} = State,
	case Request of
		{add_row, Key, Value} -> dets:insert(ActiveTable, {Key, Value});
		{delete_row, Key} ->
			dets:delete(ActiveTable, Key),
			dets:delete(InactiveTable, Key);
		{update_row, Key, Value} ->
			case dets:member(ActiveTable, Key) of
				true -> dets:insert(ActiveTable, {Key, Value});
				false ->
					case dets:member(InactiveTable, Key) of
						true -> dets:insert(InactiveTable, {Key, Value});
						false -> ok
					end
			end;
		{add_inactive_row, Key, Value} ->
			dets:insert(InactiveTable, {Key, Value});
		{make_row_active, Key} ->
			case dets:lookup(InactiveTable, Key) of
				[Pair | _ ] ->
					dets:insert(ActiveTable, Pair),
					dets:delete(InactiveTable, Key);
				_ -> ok
			end;
		{make_row_inactive, Key} ->
			case dets:lookup(ActiveTable, Key) of
				[Pair | _ ] ->
					dets:insert(InactiveTable, Pair),
					dets:delete(ActiveTable, Key);
				_ -> ok
			end

	end,
	{noreply, State}.

handle_call(Request, From, State) ->
	{ActiveTable, InactiveTable} = State,
	case Request of 
		{get_row, Key} ->
			Match = dets:lookup(ActiveTable, Key),
			case Match of
				[Pair | _] -> {reply, Pair, State};
				_ -> {reply, no_match, State}
			end;
		{filter, Function} ->
			Result =
				dets:foldl(fun(Pair, Acc) ->
								case Function(Pair) of
									true -> [Pair | Acc];
									_ -> Acc
								end
							end, [], ActiveTable),
			{reply, Result, State};
		{get_all_active_rows} ->
			Keys = dets:foldl(fun(Pair, Acc) -> [Pair | Acc] end, [], ActiveTable),
			{reply, Keys, State};
		{has_row, Key} ->
			HasKey = dets:member(ActiveTable, Key) or dets:member(InactiveTable, Key),
			{reply, HasKey, State}
	end.

terminate(_, {ActiveTable, InactiveTable}) ->
	dets:close(ActiveTable),
	dets:close(InactiveTable).


