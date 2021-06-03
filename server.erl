-module(server).
-export([start/0,stop/0,print/1]).


start()->
    Port = 5026,
    {ok, LSock} = gen_tcp:listen(Port, [binary, {packet, line}, {reuseaddr, true}]),
    Pid = spawn(fun()-> loop(maps:new(),maps:new(),createObsList(4),0) end),
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
loop(Pids,Map,ObsList,N)-> 
    receive %high priority
        {run,Delta}->
            NewMap = simulate(Map,ObsList,Delta),
            sendState(Map),
            loop(Pids,NewMap,ObsList,N)
        after 0 ->
            receive
            {run,Delta} -> 
                NewMap = simulate(Map,ObsList,Delta),
                sendState(Map),
                loop(Pids,NewMap,ObsList,N);
            {enter, Pid} ->
                        case maps:find(Pid,Pids) of
                            {ok,Value} -> 
                                NewPids = Pids,
                                NewMap = Map;
                            _ ->

                                NewPids = maps:put(Pid,true,Pids),
                                NewMap = maps:put(Pid,initial(N+1),Map)
                        end,
                        sendObs(Pid,ObsList),
                        print("user enter"),
                        loop(NewPids,NewMap,ObsList,N+1);
            {line, Data, From} ->
                        Values = maps:get(From,Map), %[X,Y,VX,VY,AX,AY,A,W,Alpha,R]
                        %parse 
                        H = string:split(Data,"n"),
                        {L, _} = lists:split(length(H) - 1, H),
                        Move = string:split(L," ",all),
                        %update
                        NewValues = accel(Values,Move),
                        NewMap =maps:update(From,NewValues,Map),
                        loop(Pids,NewMap,ObsList,N);
            {leave, Pid} ->
                        io:format("user left~n", []),
                        loop(maps:remove(Pid,Pids),maps:remove(Pid,Map),ObsList,N-1);
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

simulate(Map,ObsList,Delta)->
    %colide jogadores/jogadores
    Fun2 = fun(Key1,_,AccIn2) -> lists:merge(AccIn2,maps:fold(fun(Key2,_,AccIn1) -> check_collisionAux(Key1,Key2,Map,AccIn1) end,[],Map)) end,
    Collided = maps:fold(Fun2,[],Map), %devolve todos os pares de colisoes
    lists:foreach(fun({Key1,Key2}) -> collidePlayers(Key1,Key2,Map) end,Collided),
    %colide jogadores/paredes
    MapWalls = maps:fold(fun(Key,_,AccIn) -> collisionWalls(Key,AccIn) end,Map,Map),

    %colide jogadores/obstaculos
    MapObs = maps:fold(fun(Key,_,AccIn2) -> lists:foldr(fun(Elem,AccIn1)-> collisionObs(Key,Elem,AccIn1) end, AccIn2,ObsList) end,MapWalls,MapWalls),
    
    %colide jogadores/criaturas

    %colide criaturas/paredes

    %colide criaturas/obstaculos
    %evolui criaturas
    %evolui jogadores
    maps:fold(fun(Key,Value,AccIn) -> maps:update(Key,evolve(Value,Delta),AccIn) end,MapObs,MapObs).

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


collisionObs(Key,Obs,Map) ->
    [X,Y,VX,VY,AX,AY,A,W,Alpha,R,I] = maps:get(Key,Map),
    {X0,Y0,R0} = Obs,
    XDist = X-X0,
    YDist = Y-Y0,
    Dist = math:sqrt((XDist*XDist) + (YDist*YDist)),            
    Res =if
        Dist =< R+R0 -> 
            NormalX = XDist/Dist,
            NormalY = YDist/Dist,
            TangentX = -NormalY,
            TangentY = NormalX,
            DPTan =  VX*TangentX + VY*TangentY,
            NewVX = 1.4*TangentX * DPTan - 0.7*VX,
            NewVY =1.4*TangentY * DPTan - 0.7*VY,
            [X+1.5*NewVX*(16/1000), Y+1.5*NewVY*(16/1000),NewVX,NewVY,AX,AY,A,W,Alpha,R,I];
        true -> [X,Y,VX,VY,AX,AY,A,W,Alpha,R,I]    
    end,
    maps:update(Key,Res,Map).

collisionWalls(Key,Map)->
    [X,Y,VX,VY,AX,AY,A,W,Alpha,R,I] = maps:get(Key,Map),
    Res =
    if
        X-R =< 0 -> [X+0.5,Y,-VX,VY,AX,AY,A,W,Alpha,R,I];
        Y-R =< 0 ->  [X,Y+0.5,VX,-VY,AX,AY,A,W,Alpha,R,I];
        Y+R >= 720 ->  [X,Y-0.5,VX,-VY,AX,AY,A,W,Alpha,R,I];
        X+R >= 1280 ->  [X-0.5,Y,-VX,VY,AX,AY,A,W,Alpha,R,I];
        true -> [X,Y,VX,VY,AX,AY,A,W,Alpha,R,I]
    end,
maps:update(Key,Res,Map).

collidePlayers(Key1,Key2,Map)->
    [_,_,_,_,_,_,_,_,_,R1,_] = maps:get(Key1,Map),
    [_,_,_,_,_,_,_,_,_,R2,_] = maps:get(Key2,Map),
    if
        R1>R2 -> print("Key2 dead");
        true -> print("Key1 dead")
    end.


collision_PlayerCreatures(Player,MapPlayers,Creature,MapCreatures,ObsList)->
    [X1,Y1,VX,VY,AX,AY,A,W,Alpha,R1,I] = maps:get(Player,MapPlayers),
    [X2,Y2,VX2,VY2,R2,Type] = maps:get(Creature,MapCreatures), %[X,Y,VX,VY,R],
    SumR = R1+R2,
    XDist = X2-X1,
    YDist = Y2-Y2,
    Dist = math:sqrt((XDist*XDist) + (YDist*YDist)),
    Res = 
        if
        SumR>=Dist -> 
            {[X1,Y1,VX,VY,AX,AY,A,W,Alpha,R1+Type,I],generate_safespot(Creature,MapCreatures,ObsList)};
        SumR<Dist -> {[X1,Y1,VX,VY,AX,AY,A,W,Alpha,R1,I],[X2,Y2,VX2,VY2,R2,Type]}
    end,
    {Res1,Res2} = Res,
    {maps:update(Player,Res1,MapPlayers),maps:update(Creature,Res2,MapCreatures)}.



generate_safespot(Key,Map,ObsList)->
    ok.



evolve(Data,Delta)->
    [X,Y,Vx,Vy,Ax,Ay,A,W,Alpha,R,I] = Data,
    Dt = Delta*(1/1000),
    NewX = X+Vx*Dt,
    NewY = Y+Vy*Dt,
    NewVx = (Vx*0.9)+Ax*Dt,
    NewVy = (Vy*0.9)+Ay*Dt,
    NewA = A+W*Dt,
    NewW = (W*0.65)+Alpha*Dt,
    [NewX,NewY,NewVx,NewVy,Ax,Ay,NewA,NewW,Alpha,R,I].

accel([X,Y,VX,VY,AX,AY,A,W,Alpha,R,I],Move)->
    Q = 3000,
    J = 300,
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

sendObs(Pid,ObsList)->
    List = lists:foldl(fun({X,Y,S},AccIn) -> [io_lib:format("~.3f",[X]),io_lib:format("~.3f",[Y]),io_lib:format("~.3f",[S]) | AccIn]  end,[],ObsList),
    
    Out = string:join(List," "),
    Out2 = string:concat(Out,"\r\n"),
    Pid ! {line, Out2},
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

createObsList(0)->
    [];
createObsList(N)->
    [newObs()|createObsList(N-1)].

newObs()->
    R = 20.0*rand:uniform()+100.0,
    io:format("~p~n",[R]),
    {1000*rand:uniform()+200,600*rand:uniform()+100, R}.