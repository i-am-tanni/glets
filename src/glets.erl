-module(simplicache).

-export([
    new_table/2, lookup/2, whereis/1, identity/1
]).

new_table(TableName, Options) ->
    try
        {ok, ets:new(TableName, to_options(Options))}
    catch
        error:badarg -> {error, nil}
    end.

to_options(Opts) ->
    lists:map(fun({_, X}) -> X end, Opts).

whereis(Tab) ->
    try
        case ets:whereis(Tab) of
            undefined -> {error, nil};
            Tid -> {ok, Tid}
        end
    catch
        error:argument_error -> {error, nil}
    end.

lookup(TableName, Key) ->
    try
        {ok, ets:lookup(TableName, Key)}
    catch
        error:badarg -> {error, nil}
    end.

identity(X) -> X.
