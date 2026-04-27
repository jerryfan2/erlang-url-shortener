-module(short_handler).
-behaviour(cowboy_handler).
-export([init/2]).
-include("url_shortener.hrl").

init(Req0, State) ->
    Method = cowboy_req:method(Req0),
    Slug = cowboy_req:binding(slug, Req0),
    handle(Method, Slug, Req0, State).

handle(<<"GET">>, undefined, Req, State) ->
    Req1 = cowboy_req:reply(200, #{<<"content-type">> => <<"text/plain">>}, <<"Welcome to the URL Shortener!">>, Req),
    {ok, Req1, State};

handle(<<"GET">>, Slug, Req, State) ->
    F = fun() ->
        case mnesia:read(url_table, Slug, write) of
            [Record] ->
                UpdatedRecord = Record#url_table{clicks = Record#url_table.clicks + 1},
                mnesia:write(UpdatedRecord),
                {ok, Record#url_table.long_url};
            [] ->
                mnesia:abort(not_found)
        end
    end,

    case mnesia:transaction(F) of
        {atomic, {ok, LongUrl}} ->
            RedirectUrl = ensure_scheme(LongUrl),
            Req1 = cowboy_req:reply(302, #{<<"location">> => RedirectUrl}, Req),
            {ok, Req1, State};
        _ ->
            Req1 = cowboy_req:reply(404, #{<<"content-type">> => <<"text/plain">>}, <<"Not found">>, Req),
            {ok, Req1, State}
    end;

handle(<<"POST">>, _, Req, State) ->
    {ok, Body, Req1} = cowboy_req:read_body(Req),
    Slug = url_short_lib:get_next_base62(),
    save_url(Slug, Body),
    io:format("Created slug: ~p for url: ~p~n", [Slug, Body]),
    Req2 = cowboy_req:reply(201, #{<<"content-type">> => <<"text/plain">>}, Slug, Req1),
    {ok, Req2, State}.

ensure_scheme(<< "http", _/binary >> = Url) -> Url;
ensure_scheme(Url) -> << "https://", Url/binary >>.

save_url(Slug, LongUrl) ->
    F = fun() -> mnesia:write(#url_table{slug = Slug, long_url = LongUrl, clicks = 0, created_at = erlang:system_time(second)}) end,
    mnesia:transaction(F).