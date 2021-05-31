-module(server).
-export([start/0,stop/0]).


start()->
    Port = 1234,
    {ok, LSock} = gen_tcp:listen(Port, [binary, {packet, line}, {reuseaddr, true}]),
    Pid = spawn(fun()-> loop(maps:new(),maps:new()) end),
    spawn(fun()-> delta(16) end),
    register(?MODULE,Pid),
    spawn(fun() -> acceptor(LSock) end).

acceptor(LSock) ->
    {ok, Sock} = gen_tcp:accept(LSock),
    spawn(fun() -> acceptor(LSock) end),
    ?MODULE ! {enter, self()},
    user(Sock).

%Pids Map Pid -> {Password,isOnline}
%Positions Map Pid -> Position
%Criaturas Map 
loop(Pids,Map)-> 
    receive %high priority
        {run,Delta}->
            simulate(Map,Delta)
        after 0 ->
            receive
            {run} -> 
                simulate(Map);
            {enter, Pid} ->
                        case maps:find(Pid,Pids) of
                            {ok,Value} -> 
                                NewPids = Pids,
                                NewMap = Map;
                            _ ->
                                NewPids = maps:put(Pid,true,Pids),
                                NewMap = maps:put(Pid,[0,0,0,0,0,0],Map)
                        end,
                        loop(NewPids,NewMap);
            {line, Data, From} ->
                        Values = maps:get(From,Map), %[X,Y,VX,VY,AX,AY,A,W,Alpha,R]
                        %parse 
                        Move = string:split(Data," ",all),
                        %update
                        NewValues = accel(Values,Move),
                        maps:update(From,NewValues,Map),
                        loop(Pids,Map);
            {leave, Pid} ->
                        io:format("user left~n", []),
                        loop(maps:remove(Pid,Pids),maps:remove(Pid,Map));
            {stop} -> ok
            end
        
    end.


%Player ->
% Pos X,Y
% Vel X,Y
% Accel X,Y
% Angle A
% Vel Rot W
% Accel Rot Alpha
% Charge 1,2

simulate(Map)->
    ok.


check_collision({X1,Y1,R1},{X2,Y2,R2})-> 
    Xdist = X2-X1,
    Ydist = Y2-Y1,
    Dist = math:sqrt((Xdist*Xdist) + (Ydist*Ydist)),
    SumR = R1+R2,
    R = 
    if
        SumR>Dist -> true;
        SumR<Dist -> false
    end,
R.


accel([X,Y,VX,VY,AX,AY,A,W,Alpha,R],Move)->
    Q = 0.1,
    
    case lists:member("u", Move) of
        true ->
            AX = AX+Q*math:cos(A),
            AY = AY+Q*math:sin(A)
    end,
    case lists:member("l", Move) of
        true->
            Alpha = Alpha+Q
    end,
    case lists:member("r", Move) of
        true->
            Alpha = Alpha-Q
    end,
[X,Y,VX,VY,AX,AY,A,W,Alpha,R].
    


delta(Delta)->
    receive
        after Delta ->
            ?MODULE ! {run,Delta}
    end.

stop()->
    ?MODULE ! {stop}.

user(Sock) ->
    receive
        {line, Data} ->
            gen_tcp:send(Sock, Data),
            user(Sock);
        {tcp, _, Data} ->
            ?MODULE ! {line, Data,self()},
            user(Sock);
        {tcp_closed, _} ->
            ?MODULE ! {leave, self()};
        {tcp_error, _, _} ->
            ?MODULE ! {leave, self()}
    end.