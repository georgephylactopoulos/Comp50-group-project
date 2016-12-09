
-module(util).

-export([parallel_map/2, parallel_filter/2]).

parallel_map(Fun, List) ->
	CreateProcess = fun(Item) ->
							Process = fun () ->
											  Result = Fun(Item),
											  receive
												  {From, get_result} ->
													  From ! {result, Result}
											  end
									  end,
							spawn(Process)
					end,
	Processes = lists:map(CreateProcess, List),
	GetResult = fun(Pid) ->
						Pid ! {self(), get_result},
						receive {result, Result} -> Result end,
						Result
				end,
	lists:map(GetResult, Processes).

parallel_filter(Fun, List) ->
  Results = parallel_map(fun(Elem) ->
	case Fun(Elem) of
	  true -> [Elem];
	  false -> []
	end
  end, List),
  lists:merge(Results).