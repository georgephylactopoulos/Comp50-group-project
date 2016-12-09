
c(tablet_server).
c(client).
c(master_server).
c(health_check).
c(monitor).
c(util).



Tablet1 = tablet_server:start(unique_name1).
Tablet2 = tablet_server:start(unique_name2).
Tablet3 = tablet_server:start(unique_name3).

Master = master_server:start(master_name).

Monitor = monitor:start(10, Master).

gen_server:cast(Tablet1, {clear_everything}).
gen_server:cast(Tablet2, {clear_everything}).
gen_server:cast(Tablet3, {clear_everything}).

gen_server:cast(Master, {add_tablet, Tablet1}).
gen_server:cast(Master, {add_tablet, Tablet2}).
gen_server:cast(Master, {add_tablet, Tablet3}).

client:add_row(Master, "Hello", "world").

timer:sleep(1000).

client:get_row(Master, "Hello").
client:get_row(Master, "does not exist").

client:update_row(Master, "Hello", "new value").
client:get_row(Master, "Hello").

client:add_row(Master, 1, "turtle").
client:add_row(Master, 2, "duck").
client:add_row(Master, 3, "turtle").

client:filter(Master, fun({Key, Value}) -> Value == "turtle" end).

client:delete_row(Master, 3).

client:filter(Master, fun({Key, Value}) -> Value == "turtle" end).

'run health check'.

health_check:run(Master, 2).


'tablets before '.

gen_server:call(Master, {get_tablets}).

exit(Tablet1, reason).

timer:sleep(1000).

'tablets after killing tablet1'.

gen_server:call(Master, {get_tablets}).

'run health check again'.

health_check:run(Master, 2).

client:get_row(Master, "Hello").
client:get_row(Master, 1).
client:get_row(Master, 2).


