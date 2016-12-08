
-module(health_check).

-export([run/2]).

run(Master, Copies) ->
	% Ask the master who the tablets are.
	Tablets = gen_server:call(Master, {get_tablets}),
	Problems = lists:flatten(find_problems(Tablets, Copies)),
	UniqueProblems = sets:to_list(sets:from_list(Problems)),
	solve_problems(Tablets, Copies, UniqueProblems).


% Helpers

% find_problems: {AllTablets, Tablet} -> [Problem]
% find_problems_key: {AllTablets, Key} -> Problem
% propose_action: {AllTablets, Problem} -> Action
% do_action: {AllTablets, Action} -> ok.

% find_problems |> solve_problem

% Data structures

% Problem = {no_active_copy, Key, TabletsWhichHaveIt}
		% | {too_many_active_copies, Key, TabletsWhichHaveActiveCopies}
		% | {not_enough_copies, Key, Value, TabletsWhichHaveIt, TabletWithActiveCopy}
		% | {inconsistent_values, Key, Value, TabletsWhichHaveIt}

find_problems(AllTablets, TargetCopies) ->
	lists:map(fun (T) -> find_problems_with_tablet(AllTablets, TargetCopies, T) end, AllTablets).

find_problems_with_tablet(AllTablets, TargetCopies, Tablet) ->
	ActiveKeys = gen_server:call(Tablet, {get_all_active_rows}),
	InactiveKeys = gen_server:call(Tablet, {get_all_inactive_rows}),
	ActiveKeyProblems = lists:map(fun(Key) -> find_problems_with_active_key(AllTablets, TargetCopies, Key) end, ActiveKeys),
	InactiveKeyProblems = lists:map(fun(Key) -> find_problems_with_inactive_key(AllTablets, Key) end, InactiveKeys),
	ActiveKeyProblems ++ InactiveKeyProblems.

find_problems_with_active_key(AllTablets, TargetCopies, Key) ->
	TabletsWithActive = lists:filter(fun(T) -> gen_server:call(T, {has_active_row, Key}) end, AllTablets),
	TabletsWithInactive = lists:filter(fun(T) -> gen_server:call(T, {has_inactive_row, Key}) end, AllTablets),
	ActiveCopies = lists:map(fun(T) -> gen_server:call(T, {get_row, Key}) end, TabletsWithActive),
	InactiveCopies = lists:map(fun(T) -> gen_server:call(T, {get_inactive_row, Key}) end, TabletsWithInactive),
	[{_, Value} | _] = ActiveCopies,
	TooManyActivesProblem =
		case length(ActiveCopies) == 1 of
			true -> [];
			false -> 
				io:format("too many active copies of key ~p~n", [Key]),
				[{too_many_active_copies, Key, TabletsWithActive}]
		end,
	NotEnoughCopiesProblem = 
		case length(ActiveCopies ++ InactiveCopies) == TargetCopies of
			true -> [];
			false -> 
				io:format("not enough copies of key ~p: only ~p~n", [Key, length(ActiveCopies ++ InactiveCopies)]),
				[{not_enough_copies, Key, Value, TabletsWithActive ++ TabletsWithInactive}]
		end,
	InconsistencyProblem = 
		case sets:size(sets:from_list(ActiveCopies ++ InactiveCopies)) of
			1 -> [];
			_ ->
				io:format("inconsistent values of key ~p : ~p ~n", [Key, ActiveCopies ++ InactiveCopies]),
				[{inconsistent_values, Key, Value, TabletsWithActive ++ TabletsWithInactive}]
		end,
	TooManyActivesProblem ++ NotEnoughCopiesProblem ++ InconsistencyProblem.

find_problems_with_inactive_key(AllTablets, Key) ->
	TabletsWithActive = lists:filter(fun(T) -> gen_server:call(T, {has_active_row, Key}) end, AllTablets),
	ActiveCopies = lists:map(fun(T) -> gen_server:call(T, {get_row, Key}) end, TabletsWithActive),
	TabletsWithInactive = lists:filter(fun(T) -> gen_server:call(T, {has_inactive_row, Key}) end, AllTablets),
	case ActiveCopies of
		[] ->
			io:format("no active copy of key ~p ~n", [Key]),
			{no_active_copy, Key, TabletsWithInactive};
		_ -> []
	end.

solve_problems(Tablets, Copies, Problems) ->
	lists:map(fun(Problem) -> solve_problem(Tablets, Copies, Problem) end, Problems).

solve_problem(Tablets, Copies, {inconsistent_values, Key, Value, TabletsWithRow}) ->
	io:format("Updating values for Key: ~p Value: ~p ~n", [Key, Value]),
	lists:map(fun(T) -> gen_server:cast(T, {update_row, Key, Value}) end, TabletsWithRow);
solve_problem(Tablets, Copies, {too_many_active_copies, Key, TabletsWithActive}) ->
	[_ | Rest] = TabletsWithActive,
	io:format("Deleting active row with Key: ~p from Tablets: ~p ~n", [Key, Rest]),
	lists:map(fun (T) -> gen_server:cast(T, {delete_row, Key}) end, Rest);
solve_problem(Tablets, Copies, {no_active_copy, Key, TabletsWithInactive}) ->
	[First | _] = TabletsWithInactive,
	io:format("Making row: ~p active on tablet:~p~n", [Key, First]),
	gen_server:cast(First, {make_row_active, Key});
solve_problem(Tablets, Copies, {not_enough_copies, Key, Value, TabletsWithRow}) ->
	TabletsWithoutRow = sets:to_list(sets:subtract(sets:from_list(Tablets), sets:from_list(TabletsWithRow))),
	TabletsToAdd = lists:sublist(TabletsWithoutRow, Copies - length(TabletsWithRow)),
	io:format("Adding inactive copies of row: ~p on tablets: ~p ~n", [Key, TabletsToAdd]),
	lists:foreach(fun (T) -> gen_server:cast(T, {add_inactive_row, Key, Value}) end, TabletsToAdd).
