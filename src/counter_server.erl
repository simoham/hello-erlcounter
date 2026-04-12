%%%-------------------------------------------------------------------
%%% @doc
%%% Simple counter server using gen_server behavior
%%% @end
%%%-------------------------------------------------------------------
-module(counter_server).
-behaviour(gen_server).

%% API
-export([start_link/0, start_link/1]).
-export([increment/0, decrement/0, get_value/0, reset/0, set_value/1]).

%% gen_server callbacks
-export([init/1, handle_call/3, handle_cast/2, handle_info/2, terminate/2, code_change/3]).

%% State record
-record(state, {
    value = 0 :: integer()
}).

%%%===================================================================
%%% API functions
%%%===================================================================

%% @doc Starts the counter server with default name counter_server
-spec start_link() -> {ok, pid()} | ignore | {error, term()}.
start_link() ->
    start_link(counter_server).

%% @doc Starts the counter server with custom name
-spec start_link(atom()) -> {ok, pid()} | ignore | {error, term()}.
start_link(ServerName) ->
    gen_server:start_link({local, ServerName}, ?MODULE, [], []).

%% @doc Increments the counter by 1
-spec increment() -> ok | {error, term()}.
increment() ->
    gen_server:cast(counter_server, increment).

%% @doc Decrements the counter by 1
-spec decrement() -> ok | {error, term()}.
decrement() ->
    gen_server:cast(counter_server, decrement).

%% @doc Gets the current counter value
-spec get_value() -> {ok, integer()} | {error, term()}.
get_value() ->
    gen_server:call(counter_server, get_value).

%% @doc Resets the counter to 0
-spec reset() -> ok | {error, term()}.
reset() ->
    gen_server:cast(counter_server, reset).

%% @doc Sets the counter to a specific value
-spec set_value(integer()) -> ok | {error, term()}.
set_value(Value) when is_integer(Value) ->
    gen_server:cast(counter_server, {set_value, Value}).

%%%===================================================================
%%% gen_server callbacks
%%%===================================================================

%% @private
init([]) ->
    {ok, #state{value = 0}}.

%% @private
handle_call(get_value, _From, State) ->
    {reply, {ok, State#state.value}, State};

handle_call(_Request, _From, State) ->
    {reply, {error, unknown_call}, State}.

%% @private
handle_cast(increment, State) ->
    NewValue = State#state.value + 1,
    {noreply, State#state{value = NewValue}};

handle_cast(decrement, State) ->
    NewValue = State#state.value - 1,
    {noreply, State#state{value = NewValue}};

handle_cast(reset, State) ->
    {noreply, State#state{value = 0}};

handle_cast({set_value, Value}, State) ->
    {noreply, State#state{value = Value}};

handle_cast(_Request, State) ->
    {noreply, State}.

%% @private
handle_info(_Info, State) ->
    {noreply, State}.

%% @private
terminate(_Reason, _State) ->
    ok.

%% @private
code_change(_OldVsn, State, _Extra) ->
    {ok, State}.
