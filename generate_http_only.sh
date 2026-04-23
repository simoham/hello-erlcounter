#!/bin/bash

# add_cowboy_http_api.sh
# Adds Cowboy HTTP API to existing counter application

set -e

echo "Adding Cowboy HTTP API to counter application..."

# Add cowboy and jsx dependencies to rebar.config
cat > rebar.config << 'EOF'
{erl_opts, [debug_info]}.
{deps, [
    {cowboy, "2.10.0"},
    {jsx, "3.1.0"}
]}.

{shell, [
    {apps, [counter_app]}
]}.
EOF

# Create counter_http_handler module
cat > src/counter_http_handler.erl << 'EOF'
%%%-------------------------------------------------------------------
%%% @doc
%%% Cowboy HTTP handler for counter API with JSON responses
%%% @end
%%%-------------------------------------------------------------------
-module(counter_http_handler).
-behaviour(cowboy_handler).

%% API
-export([init/2, terminate/3]).

%%%===================================================================
%%% cowboy_handler callbacks
%%%===================================================================

init(Req0, State) ->
    Method = cowboy_req:method(Req0),
    Path = cowboy_req:path(Req0),

    case {Method, Path} of
        {<<"GET">>, <<"/api/counter">>} ->
            handle_get_counter(Req0);
        {<<"POST">>, <<"/api/counter/increment">>} ->
            handle_increment(Req0);
        {<<"POST">>, <<"/api/counter/decrement">>} ->
            handle_decrement(Req0);
        {<<"POST">>, <<"/api/counter/reset">>} ->
            handle_reset(Req0);
        {<<"POST">>, <<"/api/counter/set">>} ->
            handle_set_counter(Req0);
        _ ->
            handle_not_found(Req0)
    end.

terminate(_Reason, _Req, _State) ->
    ok.

%%%===================================================================
%%% API Handlers
%%%===================================================================

%% GET /api/counter - Get current counter value
handle_get_counter(Req) ->
    case counter_server:get_value() of
        {ok, Value} ->
            Response = jsx:encode(#{status => <<"success">>, value => Value}),
            cowboy_req:reply(200, #{<<"content-type">> => <<"application/json">>}, Response, Req);
        {error, Reason} ->
            Response = jsx:encode(#{status => <<"error">>, message => list_to_binary(io_lib:format("~p", [Reason]))}),
            cowboy_req:reply(500, #{<<"content-type">> => <<"application/json">>}, Response, Req)
    end.

%% POST /api/counter/increment - Increment counter
handle_increment(Req) ->
    counter_server:increment(),
    case counter_server:get_value() of
        {ok, Value} ->
            Response = jsx:encode(#{status => <<"success">>, operation => <<"increment">>, value => Value}),
            cowboy_req:reply(200, #{<<"content-type">> => <<"application/json">>}, Response, Req);
        {error, Reason} ->
            Response = jsx:encode(#{status => <<"error">>, message => list_to_binary(io_lib:format("~p", [Reason]))}),
            cowboy_req:reply(500, #{<<"content-type">> => <<"application/json">>}, Response, Req)
    end.

%% POST /api/counter/decrement - Decrement counter
handle_decrement(Req) ->
    counter_server:decrement(),
    case counter_server:get_value() of
        {ok, Value} ->
            Response = jsx:encode(#{status => <<"success">>, operation => <<"decrement">>, value => Value}),
            cowboy_req:reply(200, #{<<"content-type">> => <<"application/json">>}, Response, Req);
        {error, Reason} ->
            Response = jsx:encode(#{status => <<"error">>, message => list_to_binary(io_lib:format("~p", [Reason]))}),
            cowboy_req:reply(500, #{<<"content-type">> => <<"application/json">>}, Response, Req)
    end.

%% POST /api/counter/reset - Reset counter to 0
handle_reset(Req) ->
    counter_server:reset(),
    Response = jsx:encode(#{status => <<"success">>, operation => <<"reset">>, value => 0}),
    cowboy_req:reply(200, #{<<"content-type">> => <<"application/json">>}, Response, Req).

%% POST /api/counter/set - Set counter to specific value
%% Request body: {"value": 42}
handle_set_counter(Req0) ->
    {ok, Body, Req1} = cowboy_req:read_body(Req0),
    try
        #{<<"value">> := Value} = jsx:decode(Body, [return_maps]),
        counter_server:set_value(Value),
        Response = jsx:encode(#{status => <<"success">>, operation => <<"set">>, value => Value}),
        cowboy_req:reply(200, #{<<"content-type">> => <<"application/json">>}, Response, Req1)
    catch
        _:Error ->
            ErrorMsg = list_to_binary(io_lib:format("Invalid request: ~p", [Error])),
            Response = jsx:encode(#{status => <<"error">>, message => ErrorMsg}),
            cowboy_req:reply(400, #{<<"content-type">> => <<"application/json">>}, Response, Req1)
    end.

%% 404 Handler
handle_not_found(Req) ->
    Response = jsx:encode(#{status => <<"error">>, message => <<"Endpoint not found">>}),
    cowboy_req:reply(404, #{<<"content-type">> => <<"application/json">>}, Response, Req).
EOF

# Create counter_http_server module
cat > src/counter_http_server.erl << 'EOF'
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
EOF

# Update counter_supervisor to include HTTP server
cat > src/counter_supervisor.erl << 'EOF'
%%%-------------------------------------------------------------------
%%% @doc
%%% Supervisor for the counter server and HTTP server
%%% @end
%%%-------------------------------------------------------------------
-module(counter_supervisor).
-behaviour(supervisor).

%% API
-export([start_link/0]).

%% Supervisor callbacks
-export([init/1]).

%%%===================================================================
%%% API functions
%%%===================================================================

-spec start_link() -> {ok, pid()} | ignore | {error, term()}.
start_link() ->
    supervisor:start_link({local, ?MODULE}, ?MODULE, []).

%%%===================================================================
%%% Supervisor callbacks
%%%===================================================================

init([]) ->
    SupFlags = #{
        strategy => one_for_one,
        intensity => 1,
        period => 5
    },

    ChildSpecs = [
        #{
            id => counter_server,
            start => {counter_server, start_link, []},
            restart => permanent,
            shutdown => 5000,
            type => worker,
            modules => [counter_server]
        },
        #{
            id => counter_http_server,
            start => {counter_http_server, start_link, []},
            restart => permanent,
            shutdown => 5000,
            type => worker,
            modules => [counter_http_server]
        }
    ],

    {ok, {SupFlags, ChildSpecs}}.
EOF

# Create a test script for the API
cat > test_api.sh << 'EOF'
#!/bin/bash

echo "Testing Counter HTTP API"
echo "========================"
echo ""

echo "1. Get initial counter value:"
curl -s http://localhost:8080/api/counter | jq '.'
echo ""

echo "2. Increment counter:"
curl -s -X POST http://localhost:8080/api/counter/increment | jq '.'
echo ""

echo "3. Increment again:"
curl -s -X POST http://localhost:8080/api/counter/increment | jq '.'
echo ""

echo "4. Get current value:"
curl -s http://localhost:8080/api/counter | jq '.'
echo ""

echo "5. Decrement counter:"
curl -s -X POST http://localhost:8080/api/counter/decrement | jq '.'
echo ""

echo "6. Set counter to 100:"
curl -s -X POST http://localhost:8080/api/counter/set \
  -H "Content-Type: application/json" \
  -d '{"value": 100}' | jq '.'
echo ""

echo "7. Get final value:"
curl -s http://localhost:8080/api/counter | jq '.'
echo ""

echo "8. Reset counter:"
curl -s -X POST http://localhost:8080/api/counter/reset | jq '.'
echo ""

echo "9. Verify reset:"
curl -s http://localhost:8080/api/counter | jq '.'
echo ""
EOF

chmod +x test_api.sh

# Create a simple API usage example
cat > examples/api_usage.erl << 'EOF'
%%%-------------------------------------------------------------------
%%% @doc
%%% Example of using the counter HTTP API from Erlang
%%% @end
%%%-------------------------------------------------------------------
-module(api_usage).
-export([test/0, get_value/0, increment/0, decrement/0, reset/0, set_value/1]).

-define(API_URL, "http://localhost:8080").

test() ->
    io:format("Testing Counter API from Erlang~n"),
    io:format("============================~n~n"),

    {ok, Initial} = get_value(),
    io:format("Initial value: ~p~n", [Initial]),

    {ok, _} = increment(),
    {ok, AfterInc} = get_value(),
    io:format("After increment: ~p~n", [AfterInc]),

    {ok, _} = increment(),
    {ok, AfterInc2} = get_value(),
    io:format("After second increment: ~p~n", [AfterInc2]),

    {ok, _} = decrement(),
    {ok, AfterDec} = get_value(),
    io:format("After decrement: ~p~n", [AfterDec]),

    {ok, _} = set_value(42),
    {ok, AfterSet} = get_value(),
    io:format("After setting to 42: ~p~n", [AfterSet]),

    {ok, _} = reset(),
    {ok, AfterReset} = get_value(),
    io:format("After reset: ~p~n", [AfterReset]),

    ok.

get_value() ->
    case httpc:request(get, {?API_URL ++ "/api/counter", []}, [], []) of
        {ok, {{_, 200, _}, _, Body}} ->
            {ok, jsx:decode(Body)};
        Error ->
            {error, Error}
    end.

increment() ->
    case httpc:request(post, {?API_URL ++ "/api/counter/increment", [], "application/json", ""}, [], []) of
        {ok, {{_, 200, _}, _, Body}} ->
            {ok, jsx:decode(Body)};
        Error ->
            {error, Error}
    end.

decrement() ->
    case httpc:request(post, {?API_URL ++ "/api/counter/decrement", [], "application/json", ""}, [], []) of
        {ok, {{_, 200, _}, _, Body}} ->
            {ok, jsx:decode(Body)};
        Error ->
            {error, Error}
    end.

reset() ->
    case httpc:request(post, {?API_URL ++ "/api/counter/reset", [], "application/json", ""}, [], []) of
        {ok, {{_, 200, _}, _, Body}} ->
            {ok, jsx:decode(Body)};
        Error ->
            {error, Error}
    end.

set_value(Value) ->
    JsonBody = jsx:encode(#{value => Value}),
    Headers = [{"Content-Type", "application/json"}],
    case httpc:request(post, {?API_URL ++ "/api/counter/set", Headers, "application/json", JsonBody}, [], []) of
        {ok, {{_, 200, _}, _, Body}} ->
            {ok, jsx:decode(Body)};
        Error ->
            {error, Error}
    end.
EOF

echo "Cowboy HTTP API added successfully!"
echo ""
echo "To build and run:"
echo "  rebar3 compile"
echo "  rebar3 shell"
echo ""
echo "API Endpoints (JSON responses):"
echo "  GET  http://localhost:8080/api/counter"
echo "  POST http://localhost:8080/api/counter/increment"
echo "  POST http://localhost:8080/api/counter/decrement"
echo "  POST http://localhost:8080/api/counter/reset"
echo "  POST http://localhost:8080/api/counter/set"
echo ""
echo "Test with curl:"
echo "  curl http://localhost:8080/api/counter"
echo "  curl -X POST http://localhost:8080/api/counter/increment"
echo "  curl -X POST http://localhost:8080/api/counter/set -H 'Content-Type: application/json' -d '{\"value\": 42}'"
echo ""
echo "Run the test script (requires jq):"
echo "  ./test_api.sh"
