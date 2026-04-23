%%%-------------------------------------------------------------------
%%% @doc
%%% Cowboy HTTP server for counter API
%%% @end
%%%-------------------------------------------------------------------
-module(counter_http_server).
-behaviour(application).

%% API
-export([start/0, stop/0, start/2, stop/1]).
-export([start_link/0]).

%%%===================================================================
%%% API functions
%%%===================================================================

start() ->
    application:ensure_all_started(counter_http_server).

stop() ->
    application:stop(counter_http_server).

start_link() ->
    start(normal, []).

%%%===================================================================
%%% Application callbacks
%%%===================================================================

start(_StartType, _StartArgs) ->
    Dispatch = cowboy_router:compile([
        {'_', [
            {"/api/counter", counter_http_handler, []},
            {"/api/counter/increment", counter_http_handler, []},
            {"/api/counter/decrement", counter_http_handler, []},
            {"/api/counter/reset", counter_http_handler, []},
            {"/api/counter/set", counter_http_handler, []}
        ]}
    ]),

    {ok, _} = cowboy:start_clear(counter_http,
        [{port, 8080}],
        #{env => #{dispatch => Dispatch}}
    ),

    io:format("~n=== Counter HTTP API Server Started ===~n"),
    io:format("API Base URL: http://localhost:8080/api~n"),
    io:format("Endpoints:~n"),
    io:format("  GET  /api/counter           - Get counter value~n"),
    io:format("  POST /api/counter/increment - Increment counter~n"),
    io:format("  POST /api/counter/decrement - Decrement counter~n"),
    io:format("  POST /api/counter/reset     - Reset counter~n"),
    io:format("  POST /api/counter/set       - Set counter value~n"),
    io:format("====================================~n~n"),

    {ok, self()}.

stop(_State) ->
    cowboy:stop_listener(counter_http),
    ok.
