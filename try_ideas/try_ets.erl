
% Trying out dets and ets

% Makes table_name a global
Table = ets:new(table_name, [{write_concurrency, true}, {read_concurrency, true}]).

ets:insert(Table, {"Hello", "World"}).


% Create/Open the dets_table dets file
{ok, DiskTable} = dets:open_file(dets_table, []).

% Load and unload 
ets:to_dets(Table, DiskTable).
ets:from_dets(Table, DiskTable).

ets:lookup(Table, "Hello").

% Update value of the "Hello" key
dets:insert(dets_table, [{"Hello", "newValue"}]).
ets:from_dets(Table, DiskTable).

ets:lookup(Table, "Hello").

ets:tab2list(Table).

ets:insert(Table, {"Another", "Key"}).

ets:tab2list(Table).
