c(tablet_server).
Pid = tablet_server:start().

This = self().

% Pid ! {addActiveRow, "Hello", "world"}.
% Pid ! {queryW, fun(Key, Value) -> "world2" end}.
% Pid ! {queryR, fun(Key, Value) -> This ! {read, {Key, Value}} , Key end}.
% receive {read, {Key, Value}} -> io:format("~s", [Value]), yup end.




% riak - nosql in erlang (basho)
% dets
% ets

