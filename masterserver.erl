-module(masterserver).
-export([start/1,add_tablet/2,update_clients/1,loop/2,delete_tablet/2,print_tablet_list/1,print_client_list/1]).


%The way this has been implemented now, we need to call update_clients
%every time we add a tablet. However, we might as well just make add_tablet
%call update_clients().

start(MasterServerName) ->
	Pid = spawn(masterserver,loop,[[],[]]),
	register(MasterServerName,Pid),
	Pid.

%Tablet must have the form {registeredprocessname(atom),node(atom)}
add_tablet(MasterServerLoopName,Tablet) -> 
	{MasterServerLoopName, node()} ! {add_tablet,Tablet}.

update_clients(MasterServerLoopName)-> 
	{MasterServerLoopName, node()} ! {update_clients}.

update_clients_helper([], _TabletList) -> 'Clients Updated';
update_clients_helper([H|T],TabletList) ->
	H ! {tablet_list_update, TabletList},
	update_clients_helper(T,TabletList).

%Tablet must have the form {registeredprocessname(atom),node(atom)}
delete_tablet(MasterServerLoopName, Tablet) ->
	{MasterServerLoopName, node()} ! {delete_tablet,Tablet}.

delete_item_helper([],_Item) -> [];
delete_item_helper([Item|Tail],Item) -> delete_item_helper(Tail,Item);
delete_item_helper([Head|Tail],Item) -> [Head|delete_item_helper(Tail,Item)].

%used for debugging purposes only
print_tablet_list(MasterServerLoopName) -> 
	{MasterServerLoopName, node()} ! {print_tablet_list}.

%used for debugging purposes only
print_client_list(MasterServerLoopName) -> 
	{MasterServerLoopName, node()} ! {print_client_list}.

print_list_helper([]) -> [];
print_list_helper([H|T]) -> io:format("printing: ~p~n", [H]),
						    print_list_helper(T).


loop(ClientList,TabletList) -> 
	receive
		{print_tablet_list} -> print_list_helper(TabletList),
							   loop(ClientList,TabletList);
		{print_client_list} -> print_list_helper(ClientList),
							   loop(ClientList,TabletList);
		{delete_tablet, Tablet} -> NewTabletList = delete_item_helper(TabletList,Tablet),
								   loop(ClientList,NewTabletList);
		{subscribe,NewClient} -> monitor(process,NewClient),
								 loop([NewClient|ClientList],TabletList);
		{unsubscribe,ClientToRemove} -> NewClientList = delete_item_helper(ClientList,ClientToRemove),
										loop(NewClientList,TabletList);
		{add_tablet,NewTablet} -> monitor(process,NewTablet),
								  loop(ClientList,[NewTablet|TabletList]);
		{update_clients} -> update_clients_helper(ClientList,TabletList),
							loop(ClientList,TabletList);
		{'DOWN',_Reference,_Process,Process,_Reason} -> NewClientList = delete_item_helper(ClientList,Process),
														NewTabletList = delete_item_helper(TabletList,Process),
														update_clients_helper(NewClientList,NewTabletList),
												        loop(NewClientList,NewTabletList)
	end.
