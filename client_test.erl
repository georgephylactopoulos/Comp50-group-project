c(client).
c(master_server).
c(tablet_server).

{ok,Tablet1} = tablet_server:start().
Master = master_server:start(master_registered_name).
{ok,Client} = client:start(Master).

master_server:add_tablet(Master,Tablet1).
client:add_row(Client,5,5).