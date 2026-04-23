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

init(Req0, _State) ->
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
            	%% jsx:encode(#{status => <<"error">>, message => ErrorMsg}),
            	cowboy_req:reply(400, #{<<"content-type">> => <<"application/json">>}, jsx:encode(#{status => <<"error">>, message => ErrorMsg}), Req1)
    end.

%% 404 Handler
handle_not_found(Req) ->
    Response = jsx:encode(#{status => <<"error">>, message => <<"Endpoint not found">>}),
    cowboy_req:reply(404, #{<<"content-type">> => <<"application/json">>}, Response, Req).
