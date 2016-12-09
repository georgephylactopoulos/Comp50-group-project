
{ok, [[MasterNameString]]} = init:get_argument(master_name).
{ok, [[MasterNodeString]]} = init:get_argument(master_node).
{ok, [[CopiesString]]} = init:get_argument(copies).
{ok, [[RefreshRateString]]} = init:get_argument(refresh_rate).

MasterName = list_to_atom(MasterNameString).
MasterNode = list_to_atom(MasterNodeString).
{Copies, _ } = string:to_integer(CopiesString).
{RefreshRate, _ } = string:to_integer(RefreshRateString).

Master = master_server:find_master(MasterNode, MasterName).

Fun = fun(Fun) -> 
	% Run on a background process so if it dies, I don't die
	spawn(fun() -> health_check:run(Master, Copies) end),
	timer:sleep(RefreshRate),
	Fun(Fun)
end.

Fun(Fun).

