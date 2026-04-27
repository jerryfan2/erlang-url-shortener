-module(url_short_lib).
-export([get_next_base62/0, encode_base62/1]).
-include("url_shortener.hrl").

get_next_base62() ->
    {ok, NewIDBin} = eredis:q(redis_client, ["INCR", "url_id_counter"]),
    ID = binary_to_integer(NewIDBin),
    Slug = encode_base62(ID),
    Slug.

encode_base62(0) -> "0";
encode_base62(N) -> encode_base62(N, "0123456789abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ", []).

encode_base62(0, _, Acc) -> iolist_to_binary(Acc);
encode_base62(N, Chars, Acc) ->
    Idx = (N rem 62) + 1,
    Char = lists:nth(Idx, Chars),
    encode_base62(N div 62, Chars, [Char | Acc]).