c(master_server).
c(tablet_server).
c(health_check).

Master = master_server:start(name).
T1 = tablet_server:start(unique_name_1).
T2 = tablet_server:start(unique_name_2).
T3 = tablet_server:start(unique_name_3).

gen_server:cast(Master, {add_tablet, T1}).
gen_server:cast(Master, {add_tablet, T2}).
gen_server:cast(Master, {add_tablet, T3}).

gen_server:cast(T1, {clear_everything}).
gen_server:cast(T2, {clear_everything}).
gen_server:cast(T3, {clear_everything}).

gen_server:cast(T1, {add_row, "Hello", "World"}).

io:format("Put hello world on only tablet 1 and run health check expecting 3 copies~n").
timer:sleep(1000).

health_check:run(Master, 3).

io:format("Remove tablet 1 from the cluster and run health check ~n").
gen_server:cast(Master, {delete_tablet, T1}).

timer:sleep(1000).
health_check:run(Master, 3).

io:format("Create multiple active rows of Hello by readding T1  ~n").
gen_server:cast(Master, {add_tablet, T1}).

timer:sleep(1000).
health_check:run(Master, 3).

io:format("Run health check to get that 3rd backup ~n").

timer:sleep(1000).
health_check:run(Master, 3).

io:format("Create an inconsistency by setting T2's Hello to 42 manually ~n").
gen_server:cast(T2, {update_row, "Hello", 42}).

timer:sleep(1000).
health_check:run(Master, 3).

tablet_server:stop(T2).
tablet_server:stop(T3).
