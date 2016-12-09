
-module(tablet_server).

-export([start/1, stop/1]).
-export([init/1, handle_call/3, handle_cast/2, terminate/2]).

% TODO this needs a unique name (because of the dets file names)
start(UniqueName) ->
	ActiveTableName = list_to_atom(atom_to_list(UniqueName) ++ atom_to_list('_active_table')),
	InactiveTableName = list_to_atom(atom_to_list(UniqueName) ++ atom_to_list('_inactive_table')),
	{ok, ActiveTable} = dets:open_file(ActiveTableName, []),
	{ok, InactiveTable} = dets:open_file(InactiveTableName, []),
	{ok, T} = gen_server:start(tablet_server, {ActiveTable,  InactiveTable}, []),
	T.

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
			end;
		{clear_everything} ->
			dets:delete_all_objects(ActiveTable),
			dets:delete_all_objects(InactiveTable)
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
		{get_inactive_row, Key} ->
			Match = dets:lookup(InactiveTable, Key),
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
			Keys = dets:foldl(fun({Key, Val}, Acc) -> [Key | Acc] end, [], ActiveTable),
			{reply, Keys, State};
		{get_all_inactive_rows} ->
			InactiveKeys = dets:foldl(fun({Key, Val}, Acc) -> [Key | Acc] end, [], InactiveTable),
			{reply, InactiveKeys, State};
		{has_active_row, Key} ->
			HasKey = dets:member(ActiveTable, Key),
			{reply, HasKey, State};
		{has_inactive_row, Key} ->
			HasKey = dets:member(InactiveTable, Key),
			{reply, HasKey, State}
	end.

terminate(_, {ActiveTable, InactiveTable}) ->
	dets:close(ActiveTable),
	dets:close(InactiveTable).


