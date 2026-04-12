-module(naive).
-export([loop/1, start_link/0, start_link/1, rpc/2]).

start_link() ->
	start_link(0).
start_link(Value) when Value >= 0 ->
	spawn(?MODULE, loop, [Value]).

loop(Index) ->
	receive
		{From, increment} -> From ! ok, loop(Index+1);
		{From, decrement} -> From ! ok, loop(Index-1);
		{From, {set, Value}} -> From ! ok, loop(Value);
		{From, get} -> From ! {self(), Index}, loop(Index);
		{_From, stop} -> ok;
		{From, _} -> From ! error, loop(Index)
	end.

rpc(Pid, {From, Cmd}) ->
	Pid ! {From, Cmd}, %% just to remember form
	receive
		Answer -> Answer
	end;

rpc(_, _) -> {error, cmd_not_accepted}.
