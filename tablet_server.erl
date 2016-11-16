-module(tablet_server).
-compile(export_all).

% TODO protect reading and writing via a process for each file
% ActiveDictFilename = "idk.lol".
% % TODO later, decide if to split this up into shards
% InactiveDictFilename = "lsadkjflkajf.txt".

% TODO figure out if this needs anything
start_server() -> 
	ActivePid = spawn(fun () -> active_loop(dict:new(), dict:new(), 0)  end),
	InactivePid = spawn(fun () -> inactive_loop() end),
	spawn(fun () -> loop(ActivePid, InactivePid) end).

active_loop(ActiveDict, DiskActiveDict, CurrentReaders) ->
	receive
		{queryR, Function} ->
			This = self(),
			spawn(	fun () ->
						dict:map(Function, ActiveDict),
						This ! done_reading
					end),
			active_loop(ActiveDict, DiskActiveDict, CurrentReaders + 1);
		% Function has type (Key, Value) -> Value
		{queryW, Function} ->
			_ = wait_for_readers(CurrentReaders),
			NewActiveDict = dict:map(Function, ActiveDict),
			active_loop(NewActiveDict, DiskActiveDict, 0);
		{addActiveRow, Key, Value} -> 
			NewActiveDict = dict:append(Key, Value, ActiveDict),
			io:write(dict:to_list(NewActiveDict)),
			active_loop(NewActiveDict, DiskActiveDict, CurrentReaders);
		% {deleteRow, Key} ->
		% 	NewActiveDict = dict:erase(Key, ActiveDict),
		% 	active_loop(NewActiveDict, DiskActiveDict, CurrentReaders);
		{quit} -> ok
	after
		% this refresh timer is redundant
		5000 ->
			case ActiveDict of
				DiskActiveDict -> active_loop(DiskActiveDict, DiskActiveDict, CurrentReaders);
				_ ->
					% write(ActiveDict, ActiveDictFilename),
					active_loop(ActiveDict, ActiveDict, CurrentReaders)
			end
	end.

% % Tablet server loop
inactive_loop() ->
	receive
		{addInactiveRow, Key, Value} -> laod_inactives_dict_from_disk, add_this_row, write_back_to_disk;
		% {addActiveRow, Key, Value} -> 
		% 	NewActiveDict = dict:append(Key, Value, ActiveDict),
		% 	io:write(dict:to_list(NewActiveDict)),
		% 	loop(NewActiveDict, DiskActiveDict, CurrentReaders);
		{deleteInactiveRow, Key} -> todo;
		% {deleteRow, Key} ->
		% 	NewActiveDict = dict:erase(Key, ActiveDict),
		% 	loop(NewActiveDict, DiskActiveDict, CurrentReaders);
		{updateRowValue, Key, Value} -> todo;
		{updateRowActive, Key, Active} -> todo
	% after
	% 	% this refresh timer is redundant
	% 	5000 ->
	% 		case ActiveDict of
	% 			DiskActiveDict -> loop(DiskActiveDict, DiskActiveDict, CurrentReaders);
	% 			_ ->
	% 				% write(ActiveDict, ActiveDictFilename),
	% 				loop(ActiveDict, ActiveDict, CurrentReaders)
	% 		end
	end.

% % Tablet server loop
loop(ActivePid, InactivePid) ->
	receive
		{queryR, Function} -> ActivePid ! {queryR, Function};
		{queryW, Function} -> ActivePid ! {queryW, Function};
		{addInactiveRow, Key, Value} -> InactivePid ! {addInactiveRow, Key, Value};
		{addActiveRow, Key, Value} -> ActivePid ! {addActiveRow, Key, Value};
		{deleteInactiveRow, Key} -> InactivePid ! {deleteInactiveRow, Key};
		% {deleteRow, Key} -> 
		{updateRowValue, Key, Value} -> InactivePid ! {updateRowValue, Key, Value};
		{updateRowActive, Key, Active} -> InactivePid ! {updateRowActive, Key, Active}
	end,
	loop(ActivePid, InactivePid).

wait_for_readers(0) -> ok;
wait_for_readers(N) ->
	receive done_reading -> wait_for_readers(N - 1) end.

load(Filename) -> todo_returns_dict.
write(Dict, Filename) -> todo.
