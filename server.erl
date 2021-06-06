-module(server).
-export([start/0,stop/0,print/1]).


start()->
    Port = 5026,
    {ok, LSock} = gen_tcp:listen(Port, [binary, {packet, line}, {reuseaddr, true}]),
    Test = maps:new(),

    Pid = spawn(fun()-> loop(maps:new(),maps:new(),createObsList(4),maps:put(1,[50.0,50.0,100.0,100.0,0.0,0.0,0.0,0.0,0.0,10.0,10],Test),{false,false,false},queue:new()) end),
    spawn(fun()-> delta(16) end),
    register(?MODULE,Pid),
    Log = spawn(fun()-> loopManager(maps:new()) end),
    register(loginManager,Log),
    spawn(fun() -> acceptor(LSock) end),
    registered().

acceptor(LSock) ->
    {ok, Sock} = gen_tcp:accept(LSock),
    print("User connected"),
    spawn(fun() -> acceptor(LSock) end),
    Result = login(Sock),
    case Result of
        {logged,Username} ->
            ?MODULE ! {enter, self(),Username},
            user(Sock);
        _ ->
            print("User disconnected"),
            error
end.

login(Sock)->
    receive
    {tcp, _, Data} ->
        case parseL(Data) of
            {login,Msg} -> 
                loginManager ! {login,Msg,self()},
                login(Sock);
            {register,Msg}->
                loginManager  ! {register,Msg,self()},
                login(Sock);
            {error}-> login(Sock)
            end;
    {ok,login,Username} -> 
    gen_tcp:send(Sock, "true\r\n"),
    {logged,Username};
    {ok,register} -> 
    gen_tcp:send(Sock, "true\r\n"),
    login(Sock);
    {wrong_credentials} ->
        gen_tcp:send(Sock, "false\r\n"),
        login(Sock);
    {error_login,account_online}->
        gen_tcp:send(Sock, "false\r\n"),
        login(Sock);
    {error_register,account_exists} ->
        gen_tcp:send(Sock, "false\r\n"),
        login(Sock);
    {tcp_closed, _} ->
        closed;
    {tcp_error, _, _} ->
        error
end.

parseL(Data)->
    String = binary_to_list(Data),
    [State,_,Username,_,Password,_] = string:split(String," ",all),
    case  string:equal(State,"Login") of 
        true -> {login,{Username,Password}};
        _ ->
            case string:equal(State,"Register") of 
                true -> {register,{Username,Password}};
                _ -> {error}
            end
    end.


% ------------------------------------------------ LOGIN MANAGER LOOP ------------------------------------------------ %

loopManager(AccountMap)->
    receive
        {login,{Username,Password},From}-> 
            case maps:find(Username,AccountMap) of
                {ok,Value} -> 
                    {Stored_Password,IsOnline} = Value,
                    case string:equal(Stored_Password,Password) of 
                        true ->
                            case IsOnline of
                                true -> From ! {error_login,account_online}, NewMap = AccountMap;
                                _ -> NewMap = maps:update(Username,{Stored_Password,true},AccountMap),From ! {ok,login,Username}
                            end;
                        _ -> From ! {wrong_credentials}, NewMap = AccountMap
                    end;
                _ ->
                    From ! {wrong_credentials}, NewMap = AccountMap
            end,
            loopManager(NewMap);
        {register,{Username,Password},From}-> 
            case maps:find(Username,AccountMap) of
                {ok,_} -> 
                    From ! {error_register,account_exists}, NewMap = AccountMap;
                _ ->
                    From ! {ok,register},
                    NewMap = maps:put(Username,{Password,false},AccountMap)                   
            end,
            loopManager(NewMap);
        {leave,Username} ->
            {Password,_} = maps:get(Username,AccountMap),
            NewMap = maps:update(Username,{Password,false},AccountMap),
            loopManager(NewMap)
end.


% ----------------------------------------------------- GAME LOOP ---------------------------------------------------- %

loop(Pids,MapPlayers,ObsList,MapCreatures,PlayerIds,Queue)-> 
    receive %high priority
        {run,Delta}->
            {NewMapPlayers,NewMapCreatures}= simulate(MapPlayers,ObsList,MapCreatures,Delta),
            sendState(NewMapPlayers,NewMapCreatures),
            %io:format("~p~n",[maps:to_list(NewMap)]),
            loop(Pids,NewMapPlayers,ObsList,MapCreatures,PlayerIds,Queue)
        after 0 ->
            receive
            {run,Delta} -> 
                {NewMapPlayers,NewMapCreatures}= simulate(MapPlayers,ObsList,MapCreatures,Delta),
                sendState(NewMapPlayers,NewMapCreatures),
                %io:format("~p~n",[maps:to_list(NewMapCreatures)]),
                loop(Pids,NewMapPlayers,ObsList,NewMapCreatures,PlayerIds,Queue);   
            
            {enter, Pid,Username} ->
                        print("User enter"),
                        Size = maps:size(Pids),
                        if
                            Size < 3->
                                NewPids = maps:put(Pid,{Username,0},Pids),
                                {N,NewPlayerIds} = getId(PlayerIds), 
                                NeMapPlayers = maps:put(Pid,[50.0,50.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,20.0, 0],MapPlayers),
                                NewMapPlayers = maps:put(Pid,initial(Pid,NeMapPlayers,MapCreatures,ObsList,N),NeMapPlayers),
                                NewQueue = Queue;
                            true -> 
                                NewPlayerIds = PlayerIds,
                                NewPids = Pids,
                                NewMapPlayers = MapPlayers,
                                NewQueue = queue:in({Pid,Username},Queue)                            
                        end,
                        sendObs(Pid,ObsList),
                        
                        loop(NewPids,NewMapPlayers,ObsList,MapCreatures,NewPlayerIds,NewQueue);
            {line, Data, From} ->
                        Values = maps:get(From,MapPlayers), %[X,Y,VX,VY,AX,AY,A,W,Alpha,R]
                        %parse 
                        H = string:split(Data,"n"),
                        {L, _} = lists:split(length(H) - 1, H),
                        Move = string:split(L," ",all),
                        %update
                        NewValues = accel(Values,Move),
                        NewMapPlayers =maps:update(From,NewValues,MapPlayers),
                        loop(Pids,NewMapPlayers,ObsList,MapCreatures,PlayerIds,Queue);
            {leave, Pid} ->
                {Username,_} = maps:get(Pid,Pids),
                loginManager ! {leave,Username},
                print("User left"),
                        RemovedPid = maps:remove(Pid,Pids),
                        [_,_,_,_,_,_,_,_,_,_,I]= maps:get(Pid,MapPlayers),
                        RemovedPlayer = maps:remove(Pid,MapPlayers),
                        {X,Y,Z} = PlayerIds,
                        RPlayerIds =if
                            I==1 -> {false,Y,Z};
                            I==2 -> {X,false,Z};
                            I==3 -> {X,Y,false}
                        end,
                        case queue:is_empty(Queue) of
                            false ->
                                {value,{NewPid,Username},NewQueue} = queue:out(Queue),
                                NewPids = maps:put(NewPid,{Username,0},RemovedPid),
                                {N,NewPlayerIds} = getId(RPlayerIds),
                                NeMapPlayers = maps:put(NewPid,[50.0,50.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,20.0, 0],RemovedPlayer),
                                NewMapPlayers = maps:put(NewPid,initial(Pid,MapPlayers,MapCreatures,ObsList,N),NeMapPlayers);
                            true ->
                                NewPlayerIds = RPlayerIds,
                                NewQueue = Queue,
                                NewPids = RemovedPid,
                                NewMapPlayers = RemovedPlayer
                        end,
                        
                        loop(NewPids,NewMapPlayers,ObsList,MapCreatures,NewPlayerIds,NewQueue);
            {stop} -> ok
            end
end.

initial(Key,MapPlayers,MapCreatures,ObsList,N)->
    [X,Y,VX,VY,AX,AY,A,W,Alpha,R1,_] = generate_safespot(Key,MapPlayers,MapCreatures,ObsList),
    [X,Y,VX,VY,AX,AY,A,W,Alpha,R1,N].
%Player ->
% Pos X,Y
% Vel X,Y
% Accel X,Y
% Angle A
% Vel Rot W
% Accel Rot Alpha
% Charge 1,2

getId(N)->
    {X,Y,Z} = N,
    if
        X == false ->
            {1,{true,Y,Z}};
        Y == false ->
            {2,{X,true,Z}};
        Z == false ->
            {3,{X,Y,true}}
    end. 

simulate(MapPlayers,ObsList,MapCreatures,Delta)->
    %colide jogadores/jogadores
    Fun2 = fun(Key1,_,AccIn2) -> maps:fold(fun(Key2,_,AccIn1) -> check_collisionAux(Key1,Key2,MapPlayers,AccIn2++AccIn1) end ,[],MapPlayers) end,
    Collided = maps:fold(Fun2,[],MapPlayers),
    MapPlayers1 = lists:foldl(fun({Key1,Key2},AccIn) -> collidePlayers(Key1,Key2,AccIn,MapCreatures,ObsList) end,MapPlayers,Collided),
    
    %colide jogadores/paredes
    MapPlayers2 = maps:fold(fun(Key,_,AccIn) -> collisionWalls(Key,AccIn) end,MapPlayers1,MapPlayers1),

    %colide jogadores/obstaculos
    MapPlayers3 = maps:fold(fun(Key,_,AccIn2) -> lists:foldl(fun(Elem,AccIn1)-> collisionObs(Key,Elem,AccIn1) end, AccIn2,ObsList) end,MapPlayers2,MapPlayers2),
    
    %colide jogadores/criaturas
    {MapPlayers4,MapCreatures1} = maps:fold(fun(Player,_,{PAccIn2,CAccIn2}) -> maps:fold(fun(Creature,_,{PAccIn,CAccIn}) -> collision_PlayerCreatures(Player,PAccIn,Creature,CAccIn,ObsList) end ,{PAccIn2,CAccIn2},MapCreatures) end,{MapPlayers3,MapCreatures},MapPlayers3),
    %colide criaturas/paredes
    MapCreatures2 = maps:fold(fun(Key,_,AccIn) -> collisionWalls(Key,AccIn) end,MapCreatures1,MapCreatures1),
    
    %colide criaturas/obstaculos
    MapCreatures3 = maps:fold(fun(Key,_,AccIn2) -> lists:foldl(fun(Elem,AccIn1)-> collisionObs(Key,Elem,AccIn1) end, AccIn2,ObsList) end,MapCreatures2,MapCreatures2),

    %evolui criaturas
    NewMapCreatures = maps:fold(fun(Key,Value,AccIn) -> maps:update(Key,evolveCreature(Value,Delta),AccIn) end,MapCreatures3,MapCreatures3),
    %evolui jogadores
    NewMapPlayers = maps:fold(fun(Key,Value,AccIn) -> maps:update(Key,evolve(Value,Delta),AccIn) end,MapPlayers4,MapPlayers4),
    
    {NewMapPlayers,NewMapCreatures}.

check_collisionAux(Key1,Key2,Map,AccIn)->
    case Key1==Key2 of 
        false->
            case alreadyChecked(Key1,Key2,AccIn) of
                true ->
                    AccIn;
                false->
                    [X1,Y1,_,_,_,_,_,_,_,R1,_] = maps:get(Key1,Map),
                    [X2,Y2,_,_,_,_,_,_,_,R2,_] = maps:get(Key2,Map),
                    case check_collision(X1,Y1,R1,X2,Y2,R2) of
                        true->
                            [{Key1,Key2}|AccIn];
                        false->
                            AccIn
                    end
            end;
        true ->
            AccIn
    end.

alreadyChecked(Key1,Key2,AccIn1) -> 
    %io:format("~p~n",[AccIn1]),
    lists:foldl(fun({Key3,Key4},AccIn) -> AccIn or ((Key1 == Key4) and (Key2 == Key3)) end,false,AccIn1).



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

collidePlayers(Key1,Key2,MapPlayers,MapCreatures,ObsList)->
    [_,_,_,_,_,_,_,_,_,R1,_] = maps:get(Key1,MapPlayers),
    [_,_,_,_,_,_,_,_,_,R2,_] = maps:get(Key2,MapPlayers),
    
    if
        R1>R2 -> generate_safespot(Key2,MapPlayers,MapCreatures,ObsList);
        true -> generate_safespot(Key1,MapPlayers,MapCreatures,ObsList)
    end.


collision_PlayerCreatures(Player,MapPlayers,Creature,MapCreatures,ObsList)->
    [X1,Y1,VX,VY,AX,AY,A,W,Alpha,R1,I] = maps:get(Player,MapPlayers),
    [X2,Y2,VX2,VY2,AX2,AY2,A2,W2,Alpha2,R2,Type] = maps:get(Creature,MapCreatures), %[X,Y,VX,VY,R],
    SumR = R1+R2,
    XDist = X2-X1,
    YDist = Y2-Y2,
    Dist = math:sqrt((XDist*XDist) + (YDist*YDist)),
    Res = 
        if
        SumR>=Dist -> 
            {[X1,Y1,VX,VY,AX,AY,A,W,Alpha,R1+Type,I],generate_safespot(Creature,MapPlayers,MapCreatures,ObsList)};
        SumR<Dist -> {[X1,Y1,VX,VY,AX,AY,A,W,Alpha,R1,I],[X2,Y2,VX2,VY2,AX2,AY2,A2,W2,Alpha2,R2,Type]}
    end,
    {Res1,Res2} = Res,
    {maps:update(Player,Res1,MapPlayers),maps:update(Creature,Res2,MapCreatures)}.




check_collisionSpawn(X0,Y0,X1,Y1)-> 
    Xdist = X1-X0,
    Ydist = Y1-Y0,
    R = 
    if
        (abs(Xdist) =< 200) and (abs(Ydist) =< 200) -> true;
        true -> false
    end,
R.

generate_safespot(Key,MapPlayers,MapCreatures,ObsList)->
    case is_integer(Key) of
        true ->
            [_,_,VX0,VY0,AX2,AY2,A2,W2,Alpha2,R2,Type] = maps:get(Key,MapCreatures),
            X = 1100*rand:uniform() + 100,
            Y = 600*rand:uniform() + 100,
            Acc = maps:fold(fun(_,[X1,Y1,_,_,_,_,_,_,_,_,_],AccIn) -> AccIn or check_collisionSpawn(X1,Y1,X,Y) end,false,MapPlayers),
            if
                Acc == true -> generate_safespot(Key,MapPlayers,MapCreatures,ObsList);
                true -> 
                    Acc1 = lists:foldl(fun({X1,Y1,_},AccIn) -> AccIn or check_collisionSpawn(X1,Y1,X,Y) end,false,ObsList),
                    if
                        Acc1 == true -> generate_safespot(Key,MapPlayers,MapCreatures,ObsList);
                        true ->
                            Acc2 = maps:fold(fun(_,[X1,Y1,_,_,_,_,_,_,_,_,_],AccIn) -> AccIn or check_collisionSpawn(X1,Y1,X,Y) end,false,MapCreatures),
                            if
                                Acc2 == true -> generate_safespot(Key,MapPlayers,MapCreatures,ObsList);
                                true ->
                                    
                                   [X,Y,VX0,VY0,AX2,AY2,A2,W2,Alpha2,R2,Type]
                            end
                    end
            end;
            
        false -> 
            [_,_,_,_,_,_,_,_,_,R1,I] = maps:get(Key,MapPlayers),
            X = 1100*rand:uniform() + 100,
            Y = 600*rand:uniform() + 100,
            
            Acc = maps:fold(fun(_,[X1,Y1,_,_,_,_,_,_,_,_,_],AccIn) -> AccIn or check_collisionSpawn(X1,Y1,X,Y) end,false,MapPlayers),
            if
                Acc == true -> generate_safespot(Key,MapPlayers,MapCreatures,ObsList);
                true -> 
                    Acc1 = lists:foldl(fun({X1,Y1,_},AccIn) -> AccIn or check_collisionSpawn(X1,Y1,X,Y) end,false,ObsList),
                    
                    if
                        Acc1 == true -> generate_safespot(Key,MapPlayers,MapCreatures,ObsList);
                        true ->
                             
                            Acc2 = maps:fold(fun(_,[X1,Y1,_,_,_,_,_,_,_,_,_],AccIn) -> AccIn or check_collisionSpawn(X1,Y1,X,Y) end,false,MapCreatures),
                            if
                                Acc2 == true -> generate_safespot(Key,MapPlayers,MapCreatures,ObsList);
                                true ->
                                    
                                    [X,Y,0.0,0.0,0.0,0.0,0.0,0.0,0.0,R1,I]
                            end
                    end
            end
        
end.



evolve(Data,Delta)->
    [X,Y,Vx,Vy,Ax,Ay,A,W,Alpha,R,I] = Data,
    Dt = Delta*(1/1000),
    NewX = X+Vx*Dt,
    NewY = Y+Vy*Dt,
    NewVx = (Vx*0.9)+Ax*Dt, %Velocidade máxima depende do TAMANHO, A agilidade é indepente do tamanho, diminuindo com o tempo até limite minimo
    NewVy = (Vy*0.9)+Ay*Dt,
    NewA = A+W*Dt,
    NewW = (W*0.65)+Alpha*Dt,
    [NewX,NewY,NewVx,NewVy,Ax,Ay,NewA,NewW,Alpha,R,I].


evolveCreature(Data,Delta)->
    [X,Y,Vx,Vy,_,_,_,_,_,R,I] = Data,
    Dt = Delta*(1/1000),
    NewX = X+Vx*Dt,
    NewY = Y+Vy*Dt,
    NewVx = Vx,
    NewVy = Vy,
    [NewX,NewY,NewVx,NewVy,0.0,0.0,0.0,0.0,0.0,R,I].

accel([X,Y,VX,VY,_,_,A,W,_,R,I],Move)->
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
    

sendState(MapPlayers,MapCreatures)->
    List = maps:fold(fun(_,[X,Y,_,_,_,_,A,_,_,R,I],AccIn) -> [integer_to_list(I), io_lib:format("~.3f",[X]),io_lib:format("~.3f",[Y]),io_lib:format("~.3f",[A]),io_lib:format("~.3f",[R]) | AccIn] end,[],MapPlayers),
    Pids = maps:keys(MapPlayers),
    String1 = string:join(List," "),

    List2 = maps:fold(fun(_,[X,Y,_,_,_,_,A,_,_,R,_],AccIn) -> [io_lib:format("~.3f",[X]),io_lib:format("~.3f",[Y]),io_lib:format("~.3f",[A]),io_lib:format("~.3f",[R]) | AccIn] end,[],MapCreatures),
    String2 =  string:join(List2," "),
    Out = String1 ++ " Creatures " ++ String2,
    Out2 = string:concat(Out,"\r\n"),
    [Pid ! {line, Out2} || Pid <- Pids],
    ok.

sendObs(Pid,ObsList)->
    List = lists:foldl(fun({X,Y,S},AccIn) -> [io_lib:format("~.3f",[X]),io_lib:format("~.3f",[Y]),io_lib:format("~.3f",[S]) | AccIn]  end,[],ObsList),
    Out = string:join(List," "),
    Out2 = string:concat(Out,"\r\n"),
    Pid ! {line, Out2},
    ok.


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
        {leave} ->
            gen_tcp:send(Sock,"RIP\r\n");
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
    %io:format("~p~n",[R]),
    {1000*rand:uniform()+200,600*rand:uniform()+100, R}.