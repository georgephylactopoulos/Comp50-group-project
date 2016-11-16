c(tablet_server).
Pid = tablet_server:start_server().

This = self().

Pid ! {addActiveRow, "Hello", "world"}.
Pid ! {queryW, fun(Key, Value) -> "world2" end}.
Pid ! {queryR, fun(Key, Value) -> This ! {read, Key} , Key end}.
receive {read, Key} -> io:write(Key), yup end.




% riak - nosql in erlang (basho)
% dets
% ets

