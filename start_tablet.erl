
% erlang:set_cookie(node(), magic).


{ok, [[MasterNameString]]} = init:get_argument(master_name).
{ok, [[MasterNodeString]]} = init:get_argument(master_node).
{ok, [[TabletNameString]]} = init:get_argument(tablet_name).

MasterName = list_to_atom(MasterNameString).
MasterNode = list_to_atom(MasterNodeString).
TabletName = list_to_atom(TabletNameString).

Tablet = tablet_server:start(TabletName).


Master = rpc:call(MasterNode, erlang, whereis, [MasterName]).

gen_server:cast(Master, {add_tablet, Tablet}).

receive wait_forever -> ok end.


