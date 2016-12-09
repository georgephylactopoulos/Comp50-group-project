
{ok, [[MasterNameString]]} = init:get_argument(master_name).
{ok, [[MasterNodeString]]} = init:get_argument(master_node).
{ok, [[RefreshRateString]]} = init:get_argument(refresh_rate).

MasterName = list_to_atom(MasterNameString).
MasterNode = list_to_atom(MasterNodeString).
{RefreshRate, _ } = string:to_integer(RefreshRateString).

Master = master_server:find_master(MasterNode, MasterName).

monitor:start(RefreshRate, Master).

receive wait_forever -> ok end.
