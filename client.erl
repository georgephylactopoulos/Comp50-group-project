-module(client).
-export([start/1]).
-export([init/1,handle_cast/2]).
-export([add_row/3,send_add_row_message/3]).

-behaviour(gen_server).

%Starts up a client. It returns {ok,Pid}

start(MasterServerPid) -> 
	gen_server:start(client,[MasterServerPid],[]).

init(MasterServerPid) -> {ok, MasterServerPid}.

%%%%%%%%%%%%%
add_row(Loop_process_PiD,Key,Value) ->
	gen_server:cast(Loop_process_PiD,{add_row, Key, Value}).

send_add_row_message(Tablets,Key,Value) ->
	TabletListLength = length(Tablets),
	Index = rand:uniform(TabletListLength),
	Tablet = lists:nth(Index,Tablets),
	gen_server:cast(Tablet,{add_row, Key,Value}).

%%%%%%%%%%%%%%
handle_cast({add_row, Key, Value},MasterServerPid) -> 
	io:format("~p~n", [mmhereA]),
	io:format("~p~n", [MasterServerPid]),
	Tablets = gen_server:call(MasterServerPid,{get_tablets}),
	io:format("~p~n", [mmhereC]),
	send_add_row_message(Tablets, Key, Value),
	{noreply, MasterServerPid}.

