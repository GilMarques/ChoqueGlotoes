-module(server).
-export([start/0,stop/0]).


start()->
    Port = 1234,
    {ok, LSock} = gen_tcp:listen(Port, [binary, {packet, line}, {reuseaddr, true}]),
    Pid = spawn(fun()-> loop([]) end),
    register(?MODULE,Pid),
    spawn(fun() -> acceptor(LSock) end).

acceptor(LSock) ->
    {ok, Sock} = gen_tcp:accept(LSock),
    spawn(fun() -> acceptor(LSock) end),
    ?MODULE ! {enter, self()},
    user(Sock).


loop(Pids)-> 
    receive
    {enter, Pid} ->
        io:format("user entered~n", []),
        loop([Pid | Pids]);
    {line, Data} = Msg ->
        io:format("received ~p~n", [Data]),
        [Pid ! Msg || Pid <- Pids],
        loop(Pids);
    {leave, Pid} ->
        io:format("user left~n", []),
        loop(Pids -- [Pid]);
    {stop} -> ok
    end.

stop()->
    ?MODULE ! {stop}.

user(Sock) ->
    receive
        {line, Data} ->
            gen_tcp:send(Sock, Data),
            user(Sock);
        {tcp, _, Data} ->
            ?MODULE ! {line, Data},
            user(Sock);
        {tcp_closed, _} ->
            ?MODULE ! {leave, self()};
        {tcp_error, _, _} ->
            ?MODULE ! {leave, self()}
    end.