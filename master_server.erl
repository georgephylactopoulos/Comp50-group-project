-module(master_server).

-export([start/1, stop/1]).
-export([add_tablet/2,delete_tablet/2,print_tablet_list/1, find_master/2]).
-export([init/1, handle_call/3, handle_cast/2]).
-behaviour(gen_server).

start(Name) ->
	{ok, Pid} = gen_server:start(master_server, [], []),
	register(Name, Pid),
	Pid.


stop(Pid) ->
	gen_server:stop(Pid).

%Exposed functions

find_master(MasterNode, MasterName) ->
	rpc:call(MasterNode, erlang, whereis, [MasterName]).

add_tablet(Pid, Tablet) ->
	gen_server:cast(Pid,{add_tablet, Tablet}).

delete_tablet(Pid, Tablet) -> 
	gen_server:cast(Pid, {delete_tablet, Tablet}).

%%for debugging purposes
print_tablet_list(Pid) -> 
	gen_server:cast(Pid, {print_tablet_list}).


% Gen Server behavior code
% Tablets are represented by their pids
init(_) -> {ok, []}.

handle_cast({is_down,Tablet}, Tablets) ->
	NewList = lists:delete(Tablet, Tablets),
	{noreply, NewList};

handle_cast({add_tablet, Tablet}, Tablets) ->
	{noreply, [Tablet | Tablets]};

handle_cast({delete_tablet, Tablet}, Tablets) ->
	NewList = lists:delete(Tablet, Tablets),
	{noreply, NewList};

handle_cast({print_tablet_list}, Tablets) ->
	print_list_helper(Tablets),
	{noreply, Tablets}.

handle_call({get_tablets}, Sender, Tablets) ->
	{reply, Tablets, Tablets}.

%%for debugging purposes
print_list_helper([]) -> [];
print_list_helper([H|T]) -> io:format("printing: ~p~n", [H]),
						    print_list_helper(T).




