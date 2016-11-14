-module(masterserver).
-export([start/1,add_tablet/2,update_clients/1,loop/2]).


start(MasterServerName) ->
	Pid = spawn(masterserver,loop,[[],[]]),
	register(MasterServerName,Pid),
	Pid.

%Tablet must have the form {registeredprocessname(atom),node(atom)}
add_tablet(MasterServerLoopName,Tablet) -> 
	{MasterServerLoopName, node()} ! {add_tablet,Tablet}.

update_clients(MasterServerLoopName)-> 
	{MasterServerLoopName, node()} ! {update_clients}.

update_clients_helper([], TabletList) -> 'Clients Updated';
update_clients_helper([H|T],TabletList) ->
	H ! {tablet_list_update, TabletList}.

loop(ClientList,TabletList) -> 
	receive
		{subscribe,NewClient} -> loop([NewClient|ClientList],TabletList);
		{add_tablet,NewTablet} -> loop(ClientList,[NewTablet|TabletList]);
		{update_clients} -> update_clients_helper(ClientList,TabletList),
							loop(ClientList,TabletList)
	end.
