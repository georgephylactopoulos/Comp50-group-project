
erlang:set_cookie(node(), magic).

{ok, [[MasterNameString]]} = init:get_argument(master_name).

MasterName = list_to_atom(MasterNameString).

Master = master_server:start(MasterName).

receive wait_forever -> ok end.
