%%%-------------------------------------------------------------------
%%% @doc
%%% Counter application callback module
%%% @end
%%%-------------------------------------------------------------------
-module(counter_app).
-behaviour(application).

%% Application callbacks
-export([start/2, stop/1]).

%%%===================================================================
%%% Application callbacks
%%%===================================================================

-spec start(StartType :: normal | {takeover, node()} | {failover, node()},
            StartArgs :: term()) ->
    {ok, pid()} | {ok, pid(), term()} | {error, term()}.
start(_StartType, _StartArgs) ->
    counter_supervisor:start_link().

-spec stop(State :: term()) -> ok.
stop(_State) ->
    ok.
