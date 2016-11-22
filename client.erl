-module(client).
-export([start/3,loop/3,add_row/3,make_queryW/2,make_queryR/2]).

%TODO:
%convert to oTP gen server
%fake name server process 
%delete row function?

%dets
%riak (distributed no sequel databse engines)

%do reading on readig/writing from Disk (big vs small file)

start(Name, Master_Registered_Name, Master_Node) ->
	Pid = spawn(client,loop,[[], Master_Registered_Name, Master_Node]),
	register(Name,Pid),
	subscribe_to_the_master(Master_Registered_Name, Master_Node, Name),
	Pid.

add_row(Loop_process_name,Key,Value) -> 
	{Loop_process_name,node()} ! {add_row, Key, Value}.

make_queryW(Loop_process_name,Function) -> 
	{Loop_process_name,node()} ! {queryW, Function}.

send_queryW_message([], _Function) -> 'queryW made';
send_queryW_message([H|T],Function) -> 
	H ! {queryW,Function},
	send_queryW_message(T,Function).

make_queryR(Loop_process_name,Function) -> 
	{Loop_process_name,node()} ! {queryR, Function}.

send_queryR_message([], _Function) -> 'queryR made';
send_queryR_message([H|T],Function) -> 
	H ! {queryR,Function},
	send_queryR_message(T,Function).

%works
send_add_row_message(Tablet_list,Key,Value) ->
	TabletListLength = length(Tablet_list),
	Index = rand:uniform(TabletListLength),
	Tablet = lists:nth(Index,Tablet_list),
	Tablet ! {addActiveRow, Key,Value}.

%works
subscribe_to_the_master(Master_Registered_Name, Master_Node,Loop_process_name) -> 
	{Master_Registered_Name,Master_Node} ! {subscribe,{Loop_process_name,node()}}.

%I make the assumption that whenever a tablet changes in
%the cluster, the master server sends back a new altered 
%full list.
loop([], Master_Name, Master_Node) ->
	receive
		{tablet_list_update, NewList} ->  loop(NewList,Master_Name,Master_Node)
	end;

loop(Tablet_list, Master_Name,Master_Node) -> 
	receive
		{tablet_list_update, NewList} ->  loop(NewList,Master_Name,Master_Node);
		{add_row, Key, Value} -> send_add_row_message(Tablet_list,Key,Value),
								 loop(Tablet_list,Master_Name,Master_Node);
		{queryW, Function} -> send_queryW_message(Tablet_list,Function),
							  loop(Tablet_list,Master_Name,Master_Node);
		{queryR, Function} -> send_queryR_message(Tablet_list,Function),
							  loop(Tablet_list,Master_Name,Master_Node)
%		{result, NewValue} -> io:format(NewValue),
%							  loop(Tablet_list, Master_Name, Master_Node).
%
	end.


	
