%%%-------------------------------------------------------------------
%% @doc url_shortener public API
%% @end
%%%-------------------------------------------------------------------

-module(url_shortener_app).

-behaviour(application).

-export([start/2, stop/1]).

-include("url_shortener.hrl").

start(_StartType, _StartArgs) ->
    mnesia:stop(),
    mnesia:create_schema([node()]),
    ok = mnesia:start(),
    mnesia:create_table(url_table, [
        {attributes, record_info(fields, url_table)},
        {disc_copies, [node()]},
        {type, set}
    ]),

    ok = mnesia:wait_for_tables([url_table], 5000),

    Dispatch = cowboy_router:compile([
        {'_', [{"/:slug", short_handler, []},
            {"/", short_handler, []}]}
    ]),

    {ok, _} = cowboy:start_clear(
        http_listener,
        [{port, 8080}],
        #{env => #{dispatch => Dispatch}}
    ),

    url_shortener_sup:start_link().

stop(_State) ->
    mnesia:stop(),
    ok.

%% internal functions
