% -module(tablet_server).
% -compile(export_all).

% % TODO protect reading and writing via a process for each file
% % ActiveDictFilename = "idk.lol".
% % % TODO later, decide if to split this up into shards
% % InactiveDictFilename = "lsadkjflkajf.txt".

% % TODO figure out if this needs anything
% start_server() ->
% 	Pid = spawn(fun () -> 
% 		        ActiveTableMem = ets:new(active_table_mem, [{write_concurrency, true}, {read_concurrency, true}, public]),
% 		        {ok, ActiveTableDisk} = dets:open_file(active_table_disk, []),
% 	        	ets:from_dets(ActiveTableMem, ActiveTableDisk),
% 		        {ok, InactiveTable} = dets:open_file(inactive_table_disk, []),
% 		        loop(ActiveTableMem, ActiveTableDisk, InactiveTable, 0)  end),
% 	Pid.


% % % Tablet server loop
% loop(ActiveTableMem, ActiveTableDisk, InactiveTable, CurrentReaders) ->
% 	Loop = fun(Readers) -> 
% 				loop(ActiveTableMem, ActiveTableDisk, InactiveTable, Readers)
% 			end,
% 	receive
% 		{queryR, Function} ->
% 			This = self(),
% 			spawn(	fun () ->
% 						read_map(Function, ActiveTableMem),
% 						This ! done_reading
% 					end),
% 			Loop(CurrentReaders + 1);
% 		% Function has type (Key, Value) -> Value
% 		{queryW, Function} ->
% 			_ = wait_for_readers(CurrentReaders),
% 			write_map(Function, ActiveTableMem),
% 			Loop(0);
% 		{addInactiveRow, Key, Value} -> dets:insert(InactiveTable, {Key, Value}), Loop(CurrentReaders);
% 		{addActiveRow, Key, Value} ->
% 			_ = wait_for_readers(CurrentReaders),
% 			ets:insert(ActiveTableMem, [{Key, Value}]),
% 			Loop(CurrentReaders);
% 		{deleteInactiveRow, Key} ->
% 			spawn(fun() ->  dets:delete(InactiveTable, Key) end), Loop(CurrentReaders);
% 		{deleteActiveRow, Key} -> ets:delete(ActiveTableMem, Key), Loop(CurrentReaders);
% 		{updateInactiveRowValue, Key, Value} ->
% 			spawn(fun() ->  dets:insert(InactiveTable, {Key, Value}) end), Loop(CurrentReaders);
% 		{makeRowActive, Key} -> 
% 			_ = wait_for_readers(CurrentReaders),
% 			ets:insert(ActiveTableMem, dets:lookup(InactiveTable, Key)),
% 			dets:delete(InactiveTable, Key),
% 			Loop(CurrentReaders);
% 		{makeRowInactive, Key} -> 
% 			_ = wait_for_readers(CurrentReaders),
% 			dets:insert(InactiveTable, ets:lookup(ActiveTableMem, Key)),
% 			ets:delete(ActiveTableMem, Key),
% 			Loop(CurrentReaders)
% 	% after
% 		% this refresh timer is redundant
% 		% 5000 -> todo
% 			% case ActiveDict of
% 			% 	DiskActiveDict -> loop(DiskActiveDict, DiskActiveDict, CurrentReaders);
% 			% 	_ ->
% 			% 		% write(ActiveDict, ActiveDictFilename),
% 			% 		loop(ActiveDict, ActiveDict, CurrentReaders)
% 			% end
% 	end.

% wait_for_readers(0) -> ok;
% wait_for_readers(N) ->
% 	receive done_reading -> wait_for_readers(N - 1) end.

% read_map(Function, Table) ->
% 	List = ets:tab2list(Table),
% 	lists:map(fun ({Key, Value}) -> Function(Key, Value) end, List).
% write_map(Function, Table) ->
% 	List = ets:tab2list(Table),
% 	NewList = lists:map(fun ({Key, Value}) -> {Key, Function(Key, Value)} end, List),
% 	ets:insert(Table, NewList).


-module(tablet_server).
-compile(export_all).

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
		{add_row, Key, Value} -> todo;
		{delete_row, Key} -> todo;
		{update_row, Key, Value} -> todo;
		{add_inactive_row, Key, Value} -> todo;
		{make_row_active, Key} -> todo;
		{make_row_inactive, Key} -> todo
	end,
	{noreply, State}.

handle_call(Request, From, State) ->
	{ActiveTable, InactiveTable} = State,
	case Request of 
		{get_row, Key} -> todo;
		{filter, Function} -> todo;
		{get_all_active_rows} -> todo;
		{has_row, Key} -> todo
	end,
	{reply, todo_reply, State}.

terminate(_, {ActiveTable, InactiveTable}) ->
	todo_close_things.


