%%%-------------------------------------------------------------------
%% @doc counter_app top level supervisor.
%% @end
%%%-------------------------------------------------------------------

-module(counter_app_sup).

-behaviour(supervisor).

-export([start_link/0]).

-export([init/1]).

-define(SERVER, ?MODULE).

start_link() ->
    supervisor:start_link({local, ?SERVER}, ?MODULE, []).

%% sup_flags() = #{strategy => strategy(),         % optional
%%                 intensity => non_neg_integer(), % optional
%%                 period => pos_integer()}        % optional
%% child_spec() = #{id => child_id(),       % mandatory
%%                  start => mfargs(),      % mandatory
%%                  restart => restart(),   % optional
%%                  shutdown => shutdown(), % optional
%%                  type => worker(),       % optional
%%                  modules => modules()}   % optional

init([]) ->
    application:start(ranch),
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

%% internal functions
