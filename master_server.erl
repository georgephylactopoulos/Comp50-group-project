-module(master_server).

-export([start/0, stop/1]).
-export([init/1, handle_call/3, handle_cast/2]).

start() ->
	gen_server:start(master_server, [], []).

stop(Pid) ->
	gen_server:stop(Pid).

% Gen Server behavior code

% Tablets are represented by their pids

init(_) -> {ok, []}.

handle_cast({add_tablet, Tablet}, Tablets) ->
	{noreply, [Tablet | Tablets]};

handle_cast({delete_tablet, Tablet}, Tablets) ->
	NewList = lists:delete(Tablet, Tablets),
	{noreply, NewList}.

handle_call({get_tablets}, Sender, Tablets) ->
	{reply, Tablets, Tablets}.







