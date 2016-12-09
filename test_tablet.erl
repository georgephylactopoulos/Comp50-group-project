c(tablet_server).
T = tablet_server:start(unique_name).

gen_server:cast(T, {add_row, "Hello", "World"}).
gen_server:cast(T, {add_row, "SecondRow", "SecondVal"}).
gen_server:cast(T, {update_row, "Hello", "World2"}).
gen_server:call(T, {get_row, "Hello"}).
gen_server:cast(T, {add_inactive_row, "AnotherKey", "Value"}).

gen_server:cast(T, {add_row, "AnArray", [an_array]}).


timer:sleep(200).

io:format("test filter ~n").
gen_server:call(T, {filter, fun({Key, Value}) -> Key == "Hello" end}).
gen_server:call(T, {filter, fun({Key, Value}) -> true end}).

io:format("test get all active rows ~n").
gen_server:call(T, {get_all_active_rows}).

io:format("test has key ~n").
gen_server:call(T, {has_active_row, "Hello"}).
gen_server:call(T, {has_active_row, "NotAKey"}).
gen_server:call(T, {has_active_row, "AnotherKey"}).

gen_server:call(T, {get_all_inactive_rows}).


tablet_server:stop(T).


% riak - nosql in erlang (basho)
% dets
% ets

