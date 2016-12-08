c(master_server).
c(tablet_server).
c(health_check).

Master = master_server:start(name).
{ok, T1} = tablet_server:start(unique_name_1).
{ok, T2} = tablet_server:start(unique_name_2).
{ok, T3} = tablet_server:start(unique_name_3).

gen_server:cast(Master, {add_tablet, T1}).
gen_server:cast(Master, {add_tablet, T2}).
gen_server:cast(Master, {add_tablet, T3}).


io:format("RUN HEALTH CHECK~n").

health_check:run(Master, 3).

