-module(monitor).
-export([start/2, loop/3]).

start(Refresh_rate, MasterPid) ->
	Pid = spawn(monitor, loop, [[], Refresh_rate,MasterPid]),
	Pid.


%Function adds monitors to any tablets that were are not in the list of
%monitored tablets
ensure_all_tablets_are_monitored([], _Monitored_Tablets) -> ok;
ensure_all_tablets_are_monitored([H|T], Monitored_Tablets) ->
	tablet_is_already_monitored(lists:member(H, Monitored_Tablets), H),
	ensure_all_tablets_are_monitored(T, Monitored_Tablets).

%Function checks if tablet is in list of monitored tablets. If not,
%it adds monitor.
tablet_is_already_monitored(true,_H) -> ok;
tablet_is_already_monitored(false, Tablet) -> 
	monitor(process,Tablet).

%%The idea is that the function first deals with any tablets that have 
%died and then gets a new list of tablets from the master.
loop(Monitored_Tablets, Refresh_rate, MasterPid) ->
	receive
		{'DOWN', Reference, process, Process, _Reason} -> 
			gen_server:cast(MasterPid, {delete_tablet, Process}),
			demonitor(Reference, [flush]),
		    loop(Monitored_Tablets, Refresh_rate, MasterPid)
	after Refresh_rate -> ok
	end,
	% Ensure our tablet list is up to date
	Tablets = gen_server:call(MasterPid, {get_tablets}),
	ensure_all_tablets_are_monitored(Tablets, Monitored_Tablets),
	loop(Tablets, Refresh_rate, MasterPid).

