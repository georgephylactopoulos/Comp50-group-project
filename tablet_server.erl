-module(tablet_server).
-compile(export_all).

% TODO protect reading and writing via a process for each file
% ActiveDictFilename = "idk.lol".
% % TODO later, decide if to split this up into shards
% InactiveDictFilename = "lsadkjflkajf.txt".

% TODO figure out if this needs anything
start_server() ->
	ActiveTableMem = ets:new(active_table_mem, [{write_concurrency, true}, {read_concurrency, true}]),
	{ok, ActiveTableDisk} = dets:open_file(active_table_disk, []),
	ets:from_dets(ActiveTableMem, ActiveTableDisk),
	{ok, InactiveTable} = dets:open_file(inactive_table_disk, []),
	spawn(fun () -> loop(ActiveTableMem, ActiveTableDisk, InactiveTable, 0)  end).

% % Tablet server loop
loop(ActiveTableMem, ActiveTableDisk, InactiveTable, CurrentReaders) ->
	receive
		{queryR, Function} -> todo;
			% This = self(),
			% spawn(	fun () ->
			% 			dict:map(Function, ActiveDict),
			% 			This ! done_reading
			% 		end),
			% loop(ActiveDict, DiskActiveDict, CurrentReaders + 1);
		% Function has type (Key, Value) -> Value
		{queryW, Function} -> todo;
			% _ = wait_for_readers(CurrentReaders),
			% NewActiveDict = dict:map(Function, ActiveDict),
			% loop(NewActiveDict, DiskActiveDict, 0);
		{addInactiveRow, Key, Value} -> dets:insert(InactiveTable, [{Key, Value}]);
		{addActiveRow, Key, Value} ->
			_ = wait_for_readers(CurrentReaders),
			ets:insert(ActiveTableMem, [{Key, Value}]);
		{deleteInactiveRow, Key} ->
			spawn(fun() ->  dets:delete(InactiveTable, Key) end), ok;
		{deleteActiveRow, Key} -> ets:delete(ActiveTableMem, Key);
		{updateInactiveRowValue, Key, Value} ->
			spawn(fun() ->  dets:insert(InactiveTable, [{Key, Value}]) end), ok;
		{makeRowActive, Key} -> 
			_ = wait_for_readers(CurrentReaders),
			ets:insert(ActiveTableMem, dets:lookup(InactiveTable, Key)),
			dets:delete(InactiveTable, Key);
		{makeRowInactive, Key} -> 
			_ = wait_for_readers(CurrentReaders),
			dets:insert(InactiveTable, ets:lookup(ActiveTableMem, Key)),
			ets:delete(ActiveTableMem, Key)
	after
		% this refresh timer is redundant
		5000 ->
			case ActiveDict of
				DiskActiveDict -> loop(DiskActiveDict, DiskActiveDict, CurrentReaders);
				_ ->
					% write(ActiveDict, ActiveDictFilename),
					loop(ActiveDict, ActiveDict, CurrentReaders)
			end
	end.

wait_for_readers(0) -> ok;
wait_for_readers(N) ->
	receive done_reading -> wait_for_readers(N - 1) end.

load(Filename) -> todo_returns_dict.
write(Dict, Filename) -> todo.
