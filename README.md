url_shortener
=====

An OTP application

URL Shortener built using Erlang-OTP. HTTP Server built with Cowboy. Url's obtained through Redis increment, which are then encoded into Base62. Mnesia used for storing shortened url records, along with click frequencies.

Supervisor behaviour implemented for maintaing Redis client connection.

Build
-----

    $ rebar3 compile
