c(master_server).
Master = master_server:start(name).

Pid1 = spawn(fun () -> fake_tablet end).
Pid2 = spawn(fun () -> fake_tablet end).

gen_server:cast(Master, {add_tablet, Pid1}).
gen_server:cast(Master, {add_tablet, Pid2}).

gen_server:call(Master, {get_tablets}).

gen_server:cast(Master, {delete_tablet, Pid2}).

gen_server:call(Master, {get_tablets}).
