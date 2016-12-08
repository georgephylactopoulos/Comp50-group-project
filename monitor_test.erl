c(tablet_server).
c(master_server).
c(monitor).

{ok,Tablet1} = tablet_server:start(unique_name1).
'^this_is_tablet1'.
{ok,Tablet2} = tablet_server:start(unique_name2).
'^this_is_tablet2'.

Master = master_server:start(master_registered_name).

master_server:add_tablet(Master,Tablet1).
master_server:add_tablet(Master,Tablet2).

tabletsadded.

monitor:start(1,Master).

monitorstarted.

master_server:print_tablet_list(Master).

exit(Tablet2,reason).

tablet2killed.

timer:sleep(10).

master_server:print_tablet_list(Master).

tablet2shouldnotbeabove.

{ok,Tablet3} = tablet_server:start(unique_name3).

master_server:add_tablet(Master,Tablet3).

tablet3added.

exit(Tablet1,reason).

tablet1killed.

timer:sleep(10).

master_server:print_tablet_list(Master).

now_only_tablet3_should_be_above.

