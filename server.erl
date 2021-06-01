-module(server).
-export([start/0,stop/0,simulate/2,print/1]).


start()->
    Port = 5026,
    {ok, LSock} = gen_tcp:listen(Port, [binary, {packet, line}, {reuseaddr, true}]),
    Pid = spawn(fun()-> loop(maps:new(),maps:new(),0) end),
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
loop(Pids,Map,N)-> 
    receive %high priority
        {run,Delta}->
            NewMap = simulate(Map,Delta),
            sendState(Map),
            loop(Pids,NewMap,N)
        after 0 ->
            receive
            {run,Delta} -> 
                NewMap = simulate(Map,Delta),
                sendState(Map),
                loop(Pids,NewMap,N);
            {enter, Pid} ->
                        case maps:find(Pid,Pids) of
                            {ok,Value} -> 
                                NewPids = Pids,
                                NewMap = Map;
                            _ ->

                                NewPids = maps:put(Pid,true,Pids),
                                NewMap = maps:put(Pid,initial(N+1),Map)
                        end,
                        print("user enter"),
                        loop(NewPids,NewMap,N+1);
            {line, Data, From} ->
                        Values = maps:get(From,Map), %[X,Y,VX,VY,AX,AY,A,W,Alpha,R]
                        %parse 
                        H = string:split(Data,"n"),
                        {L, _} = lists:split(length(H) - 1, H),
                        Move = string:split(L," ",all),
                        %update
                        NewValues = accel(Values,Move),
                        
                        NewMap =maps:update(From,NewValues,Map),
                        loop(Pids,NewMap,N);
            {leave, Pid} ->
                        io:format("user left~n", []),
                        loop(maps:remove(Pid,Pids),maps:remove(Pid,Map),N-1);
            {stop} -> ok
            end
        
    end.

initial(N)->
    [50.0,50.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,20.0, integer_to_list(N)].
%Player ->
% Pos X,Y
% Vel X,Y
% Accel X,Y
% Angle A
% Vel Rot W
% Accel Rot Alpha
% Charge 1,2

simulate(Map,Delta)->
    Fun2 = fun(Key1,_,AccIn2) -> lists:merge(AccIn2,maps:fold(fun(Key2,_,AccIn1) -> check_collisionAux(Key1,Key2,Map,AccIn1) end,[],Map)) end,
    Collided = maps:fold(Fun2,[],Map), %devolve todos os pares de colisoes
    lists:foreach(fun(Elem) -> collide(Elem,Map) end,Collided),
    maps:fold(fun(Key,Value,AccIn) -> maps:update(Key,evolve(Value,Delta),AccIn) end,Map,Map).

check_collisionAux(Key1,Key2,Map,AccIn1)->
    case Key1==Key2 of 
        false->
            [X1,Y1,_,_,_,_,_,_,_,R1,_] = maps:get(Key1,Map),
            [X2,Y2,_,_,_,_,_,_,_,R2,_] = maps:get(Key2,Map),
            case check_collision(X1,Y1,R1,X2,Y2,R2) of
                true->
                    [{Key1,Key2}|AccIn1];
                false->
                    AccIn1
            end;
        true ->
            AccIn1
    end.


check_collision(X1,Y1,R1,X2,Y2,R2)-> 
    Xdist = X2-X1,
    Ydist = Y2-Y1,
    Dist = math:sqrt((Xdist*Xdist) + (Ydist*Ydist)),
    SumR = R1+R2,
    R = 
    if
        SumR>=Dist -> true;
        SumR<Dist -> false
    end,
R.

collide([Key1,Key2],Map)->
    [_,_,_,_,_,_,_,_,_,R1,_] = maps:get(Key1,Map),
    [_,_,_,_,_,_,_,_,_,R2,_] = maps:get(Key2,Map),
    if
        R1>R2 -> print("Key2 dead");
        true -> print("Key1 dead")
    end.


generate_safespot(Map)->
    ok.



evolve(Data,Delta)->
    [X,Y,Vx,Vy,Ax,Ay,A,W,Alpha,R,I] = Data,
    Dt = Delta*(1/1000),
    NewX = X+Vx*Dt,
    NewY = Y+Vy*Dt,
    NewVx = (Vx*0.95)+Ax*Dt,
    NewVy = (Vy*0.95)+Ay*Dt,
    NewA = A+W*Dt,
    NewW = (W*0.95)+Alpha*Dt,
    [NewX,NewY,NewVx,NewVy,Ax,Ay,NewA,NewW,Alpha,R,I].

accel([X,Y,VX,VY,AX,AY,A,W,Alpha,R,I],Move)->
    Q = 1000,
    J = 10,
    case lists:member(<<"u">>, Move) of
        true ->
            NewAX = Q*math:cos(A),
            NewAY = Q*math:sin(A);
        _ ->
            NewAX = 0.0,
            NewAY = 0.0
    end,
    case lists:member(<<"l">>, Move) of
        true->
            NewAlpha = -J;
        _ ->
            case lists:member(<<"r">>, Move) of
                true->
                    NewAlpha = J;
                _ ->
                    NewAlpha = 0.0
            end
    end,
    
[X,Y,VX,VY,NewAX,NewAY,A,W,NewAlpha,R,I].
    

sendState(Map)->
    List = maps:fold(fun(_,[X,Y,_,_,_,_,A,_,_,R,I],AccIn) -> [I, io_lib:format("~.3f",[X]),io_lib:format("~.3f",[Y]),io_lib:format("~.3f",[A]),io_lib:format("~.3f",[R]) | AccIn] end,[],Map),
    Pids = maps:keys(Map),
    Out = string:join(List," "),
    Out2 = string:concat(Out,"\r\n"),
    [Pid ! {line, Out2} || Pid <- Pids],
    ok.



normalize(X,Y) ->
    S = math:sqrt(X*X+Y*Y),
    {X/S,Y/S}.

delta(Delta)->
    receive
        after Delta ->
            ?MODULE ! {run,Delta},
            delta(Delta)
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

print(String)->
    io:format(String ++ "~n").