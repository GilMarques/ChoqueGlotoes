-module(server).
-export([start/0,stop/0,print/1]).


start()->
    Port = 5027,
    {ok, LSock} = gen_tcp:listen(Port, [binary, {packet, line}, {reuseaddr, true}]),
    Pid = spawn(fun()-> loop(maps:new(),maps:new(),createObsList(4),maps:new(),{false,false,false},{false,false,false},queue:new(),{"Player",0}) end),
    spawn(fun()-> delta(16) end),
    spawn(fun()-> spawnCreature(5000) end),
    register(?MODULE,Pid),
    Log = spawn(fun()-> loopManager(maps:new()) end),
    register(loginManager,Log),
    spawn(fun() -> acceptor(LSock) end),
    ok.

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
                                _ -> NewMap = maps:update(Username,{Stored_Password,true},AccountMap),From ! {ok,login,Username},io:format("~p logged in~n",[Username])
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
            io:format("~p logged out~n",[Username]),
            {Password,_} = maps:get(Username,AccountMap),
            NewMap = maps:update(Username,{Password,false},AccountMap),
            loopManager(NewMap)
end.



% ----------------------------------------------------- GAME LOOP ---------------------------------------------------- %

loop(Pids,MapPlayers,ObsList,MapCreatures,PlayerIds,CreatureIds,Queue,HighScore)-> 
    receive
            {run,Delta} -> 
                %print("Run"),
                
                {NewMapPlayers,NewMapCreatures}= simulate(MapPlayers,ObsList,MapCreatures,Delta),
                sendState(NewMapPlayers,NewMapCreatures,Pids,HighScore),
                loop(Pids,NewMapPlayers,ObsList,NewMapCreatures,PlayerIds,CreatureIds,Queue,HighScore);   

            {spawnCreature} ->
                    %print("Spawning"),
                    Size = maps:size(MapCreatures),
                        if
                            Size < 3->
                                {N,NewCreatureIds} = getId(CreatureIds), 
                                Rand = rand:uniform(),
                                io:format(" ~p ~n",[Rand]),
                                Type =
                                if
                                        Rand > 0.5 -> true;
                                        true -> false
                                end,
                                NeMapCreatures = maps:put(N,[50.0,50.0,500.0,500.0,off,0.0,0.0,off,10.0,3000.0,{100.0,100.0,100.0,on,on,on}, {N,Type}],MapCreatures),
                                NewMapCreatures = maps:put(N,initial(1,MapPlayers,NeMapCreatures,ObsList,{N,Type}),NeMapCreatures);
                            true -> 
                                NewMapCreatures = MapCreatures,
                                NewCreatureIds = CreatureIds       
                        end,
                        loop(Pids,MapPlayers,ObsList,NewMapCreatures,PlayerIds,NewCreatureIds,Queue,HighScore);

            {enter, Pid,Username} ->
                        print("User enter"),
                        Size = maps:size(Pids),
                        if
                            Size < 3->
                                NewPids = maps:put(Pid,{Username,0},Pids),
                                {N,NewPlayerIds} = getId(PlayerIds), 
                                NeMapPlayers = maps:put(Pid,[50.0,50.0,0.0,0.0,off,0.0,0.0,off,20.0,3000.0,{100.0,100.0,100.0,on,on,on}, 0],MapPlayers),
                                NewMapPlayers = maps:put(Pid,initial(Pid,NeMapPlayers,MapCreatures,ObsList,N),NeMapPlayers),
                                NewQueue = Queue,
                                sendObs(Pid,N,ObsList);
                            true -> 
                                NewPlayerIds = PlayerIds,
                                NewPids = Pids,
                                NewMapPlayers = MapPlayers,
                                NewQueue = queue:in({Pid,Username},Queue),    
                                Pid ! {queued}                        
                        end,
                        io:format("~p~n",[NewQueue]),
                        loop(NewPids,NewMapPlayers,ObsList,MapCreatures,NewPlayerIds,CreatureIds,NewQueue,HighScore);

            {line, Data, From} ->
                        %print("User Input"),
                        Values = maps:get(From,MapPlayers), %[X,Y,VX,VY,AX,AY,A,W,Alpha,R]
                        %parse 
                        H = string:split(Data,"n"),
                        {L, _} = lists:split(length(H) - 1, H),
                        Move = string:split(L," ",all),
                        %update
                        NewValues = accel(Values,Move),
                        NewMapPlayers = maps:update(From,NewValues,MapPlayers),
                        loop(Pids,NewMapPlayers,ObsList,MapCreatures,PlayerIds,CreatureIds,Queue,HighScore);

            {kill, Pid,I} ->
                print("Leaving"),
                io:format(" ~p ~n",[Pids]),
                Size = maps:size(Pids),
                case maps:find(Pid,Pids) of
                    {ok,_}->
                        {Username,_} = maps:get(Pid,Pids),
                        loginManager ! {leave,Username},
                        print("User left"),
                        ReMapPlayers = maps:remove(Pid,MapPlayers),
                        RemovedPid = maps:remove(Pid,Pids),
                        {X,Y,Z} = PlayerIds,
                        RPlayerIds =if
                            I==1 -> {false,Y,Z};
                            I==2 -> {X,false,Z};
                            I==3 -> {X,Y,false}
                        end,
                        case queue:is_empty(Queue) of
                            false ->
                                {{value,{NewPid,NewUsername}},NewQueue} = queue:out(Queue),
                                NewPids = maps:put(NewPid,{NewUsername,0},RemovedPid),
                                {N,NewPlayerIds} = getId(RPlayerIds),
                                NeMapPlayers = maps:put(NewPid,[50.0,50.0,0.0,0.0,off,0.0,0.0,off,20.0,3000.0,{100.0,100.0,100.0,on,on,on}, 0],ReMapPlayers),
                                NewMapPlayers = maps:put(NewPid,initial(Pid,MapPlayers,MapCreatures,ObsList,N),NeMapPlayers),
                                sendObs(NewPid,N,ObsList);
                            true ->
                                NewPlayerIds = RPlayerIds,
                                NewQueue = Queue,
                                NewPids = RemovedPid,
                                NewMapPlayers = ReMapPlayers
                            end;                 
                    error ->
                        if
                            Size < 3 ->
                                NewPids = Pids,
                                NewMapPlayers = MapPlayers,
                                NewPlayerIds = PlayerIds,
                                NewQueue = Queue;
                        true->
                        NewPids = Pids,
                        NewMapPlayers = MapPlayers,
                        NewPlayerIds = PlayerIds,
                        Username = getUser(Pid,Queue),
                        NewQueue = queue:filter(fun({P,_}) -> not(P==Username) end,Queue),
                        loginManager ! {leave,Username}
                    end
                end,
                loop(NewPids,NewMapPlayers,ObsList,MapCreatures,NewPlayerIds,CreatureIds,NewQueue,HighScore);

                {leave, Pid} ->
                case maps:find(Pid,Pids) of
                    {ok,_}->
                        {Username,_} = maps:get(Pid,Pids),
                        loginManager ! {leave,Username},
                        [_,_,_,_,_,_,_,_,_,_,_,I] = maps:get(Pid,MapPlayers),
                        print("User left"),
                        RemovedPid = maps:remove(Pid,Pids),
                        ReMapPlayers = maps:remove(Pid,MapPlayers),
                        {X,Y,Z} = PlayerIds,
                        RPlayerIds =
                        if
                            I==1 -> {false,Y,Z};
                            I==2 -> {X,false,Z};
                            I==3 -> {X,Y,false}
                        end,
                        case queue:is_empty(Queue) of
                            false ->
                                {{value,{NewPid,NewUsername}},NewQueue} = queue:out(Queue),
                                io:format(" ~p ~n",[NewQueue]),
                                NewPids = maps:put(NewPid,{NewUsername,0},RemovedPid),
                                {N,NewPlayerIds} = getId(RPlayerIds),
                                NeMapPlayers = maps:put(NewPid,[50.0,50.0,0.0,0.0,off,0.0,0.0,off,20.0,3000.0,{100.0,100.0,100.0,on,on,on}, 0],ReMapPlayers),
                                NewMapPlayers = maps:put(NewPid,initial(Pid,MapPlayers,MapCreatures,ObsList,N),NeMapPlayers),
                                sendObs(NewPid,N,ObsList);            
                            true ->
                                NewPlayerIds = RPlayerIds,
                                NewQueue = Queue,
                                NewPids = RemovedPid,
                                NewMapPlayers = ReMapPlayers
                        end;                 
                    error ->
                        NewPids = Pids,
                        NewMapPlayers = MapPlayers,
                        NewPlayerIds = PlayerIds,
                        Username = getUser(Pid,Queue),
                        NewQueue = queue:filter(fun({P,_}) -> not(P == Pid) end,Queue),
                        io:format(" ~p ~n",[NewQueue]),
                        loginManager ! {leave,Username}
                end,
            loop(NewPids,NewMapPlayers,ObsList,MapCreatures,NewPlayerIds,CreatureIds,NewQueue,HighScore);
            
            {killCreature,Cid} ->
                %print("Despawning"),
                NewMapCreatures = maps:remove(Cid,MapCreatures),
                {X,Y,Z} = CreatureIds,
                NewCreatureIds =
                    if
                        Cid==1 -> {false,Y,Z};
                        Cid==2 -> {X,false,Z};
                        Cid==3 -> {X,Y,false}
                end,
                loop(Pids,MapPlayers,ObsList,NewMapCreatures,PlayerIds,NewCreatureIds,Queue,HighScore);

            {resetScore,Pid}->
                %print("Score Reset"),
                {Username,_} = maps:get(Pid,Pids),
                NewPids = maps:update(Pid,{Username,0},Pids),
                loop(NewPids,MapPlayers,ObsList,MapCreatures,PlayerIds,CreatureIds,Queue,HighScore);

            {addScore,Pid}->
                %print("Score Add"),
                {_,HS} = HighScore,
                {Username,Score} = maps:get(Pid,Pids),
                NewPids = maps:update(Pid,{Username,Score+1},Pids),
                NewHighScore = 
                    if
                    Score+1 > HS -> {Username,Score+1};
                    true -> HighScore
                    end,
                loop(NewPids,MapPlayers,ObsList,MapCreatures,PlayerIds,CreatureIds,Queue,NewHighScore);

            {stop} -> ok
            
end.

initial(Key,MapPlayers,MapCreatures,ObsList,N)->
    [X,Y,VX,VY,AccelL,A,W,AccelR,R1,Agility,Batteries,_] = generate_safespot(Key,MapPlayers,MapCreatures,ObsList),
    [X,Y,VX,VY,AccelL,A,W,AccelR,R1,Agility,Batteries,N].

getUser(Pid,Queue) ->
    List = queue:to_list(Queue),
    {value,Value} = lists:search(fun({P,_}) -> P==Pid end,List),
    {_,Result} = Value,
    Result.

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
    MapPlayers1 = maps:fold(fun(Player1,_,AccIn2) -> maps:fold(fun(Player2,_,AccIn1) -> collidePlayers(Player1,Player2,AccIn1,MapCreatures,ObsList) end ,AccIn2,MapPlayers) end,MapPlayers,MapPlayers),
    %colide jogadores/paredes
    MapPlayers2 = maps:fold(fun(Key,_,AccIn) -> collisionWalls(Key,AccIn) end,MapPlayers1,MapPlayers1),
    %colide jogadores/obstaculos
    MapPlayers3 = maps:fold(fun(Key,_,AccIn2) -> lists:foldl(fun(Elem,AccIn1)-> collisionObs(Key,Elem,AccIn1) end, AccIn2,ObsList) end,MapPlayers2,MapPlayers2),
    %colide jogadores/criaturas
    {MapPlayers4,MapCreatures1} = maps:fold(fun(Player,_,{PAccIn2,CAccIn2}) -> maps:fold(fun(Creature,_,{PAccIn,CAccIn}) -> collision_PlayerCreatures(Player,PAccIn,Creature,CAccIn) end ,{PAccIn2,CAccIn2},MapCreatures) end,{MapPlayers3,MapCreatures},MapPlayers3),
    %colide criaturas/paredes
    MapCreatures2 = maps:fold(fun(Key,_,AccIn) -> collisionWalls(Key,AccIn) end,MapCreatures1,MapCreatures1),
    %colide criaturas/obstaculos
    MapCreatures3 = maps:fold(fun(Key,_,AccIn2) -> lists:foldl(fun(Elem,AccIn1)-> collisionObs(Key,Elem,AccIn1) end, AccIn2,ObsList) end,MapCreatures2,MapCreatures2),
    %evolui criaturas
    NewMapCreatures = maps:fold(fun(Key,Value,AccIn) -> maps:update(Key,evolveCreature(Value,Delta),AccIn) end,MapCreatures3,MapCreatures3),
    %evolui jogadores
    NewMapPlayers = maps:fold(fun(Key,Value,AccIn) -> maps:update(Key,evolve(Value,Delta),AccIn) end,MapPlayers4,MapPlayers4),
    {NewMapPlayers,NewMapCreatures}.


% ---------------------------------------------------- COLLISIONS ---------------------------------------------------- %
collisionObs(Key,Obs,Map) ->
    [X,Y,VX,VY,AccelL,A,W,AccelR,R,Agility,Batteries,I] = maps:get(Key,Map),
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
            NewVX = 2*TangentX * DPTan - VX,
            NewVY = 2*TangentY * DPTan - VY,
            Collided = true,
            [X+1.5*NewVX*(16/1000), Y+1.5*NewVY*(16/1000),NewVX,NewVY,AccelL,A,W,AccelR,R,Agility,Batteries,I];
        true ->
            Collided = false,
             [X,Y,VX,VY,AccelL,A,W,AccelR,R,Agility,Batteries,I]    
    end,
    if
        ((not(is_integer(Key))) and (Collided == true) and (R=<10.0)) -> Key! {leave},?MODULE ! {kill,Key,I};
        true-> ok
    end,
    maps:update(Key,Res,Map).

collisionWalls(Key,Map)->
    [X,Y,VX,VY,AccelL,A,W,AccelR,R,Agility,Batteries,I] = maps:get(Key,Map),
    Res =
    if
        X-R =< 0 -> 
            Collided = true,
            [X+abs(X-R),Y,-VX,VY,AccelL,A,W,AccelR,R,Agility,Batteries,I];
        Y-R =< 0 -> 
            Collided = true,
             [X,Y+abs(Y-R),VX,-VY,AccelL,A,W,AccelR,R,Agility,Batteries,I];
        Y+R >= 720 -> 
            Collided = true,
             [X,Y-abs(720-Y-R),VX,-VY,AccelL,A,W,AccelR,R,Agility,Batteries,I];
        X+R >= 1280 -> 
            Collided = true,
             [X-abs(1280-X-R),Y,-VX,VY,AccelL,A,W,AccelR,R,Agility,Batteries,I];
        true -> 
            Collided = false,
            [X,Y,VX,VY,AccelL,A,W,AccelR,R,Agility,Batteries,I]
    end,
    if
        ((not(is_integer(Key))) and (Collided == true) and (R=<10.0)) -> Key ! {leave}, ?MODULE ! {kill,Key,I};
        true-> ok
    end,
maps:update(Key,Res,Map).

collidePlayers(Key1,Key2,MapPlayers,MapCreatures,ObsList)->
    case  {maps:find(Key1,MapPlayers), maps:find(Key2,MapPlayers)} of 
        {{ok,_},{ok,_}}->
            if 
                not(Key1 == Key2)->
                    [X1,Y1,VX1,VY1,AccelL1,A1,W1,AccelR1,R1,Agility1,Batteries1,I1] = maps:get(Key1,MapPlayers),
                    [X2,Y2,VX2,VY2,AccelL2,A2,W2,AccelR2,R2,Agility2,Batteries2,I2] = maps:get(Key2,MapPlayers),
                    Xdist = X2-X1,
                    Ydist = Y2-Y1,
                    Dist = math:sqrt((Xdist*Xdist) + (Ydist*Ydist)),
                    SumR = R1+R2,
                    
                    if
                        SumR>=Dist -> 
                            if
                                R1>R2 -> 
                                    ?MODULE ! {addScore,Key1},
                                    ?MODULE ! {resetScore,Key2},
                                    NewR2 =
                                        if
                                            R2-10 < 10.0 -> 10.0;
                                            true -> R2-10
                                        end,
                                    NewAgility2 =
                                        if
                                            Agility2+500 >= 5000 -> 5000;
                                            true -> Agility2+500
                                        end,

                                    NewR1 =
                                        if
                                            R1+10 >= 40.0 -> 40.0;
                                            true -> R1+10
                                        end,
                                    NewAgility1 =
                                        if
                                            Agility1-500 =< 500 -> 500;
                                            true -> Agility1-500
                                        end,
                                    NewMap1 = maps:update(Key1,[X1,Y1,VX1,VY1,AccelL1,A1,W1,AccelR1,NewR1,NewAgility1,Batteries1,I1],MapPlayers),
                                    NewMap2 = maps:update(Key2,[X2,Y2,VX2,VY2,AccelL2,A2,W2,AccelR2,NewR2,NewAgility2,Batteries2,I2],NewMap1),
                                    maps:update(Key2,generate_safespot(Key2,NewMap2,MapCreatures,ObsList),NewMap2);                           
                                true ->
                                    ?MODULE ! {addScore,Key2},
                                    ?MODULE ! {resetScore,Key1},

                                    NewR1 =
                                        if
                                            R1-10 < 10.0 -> 10.0;
                                            true -> R1-10
                                        end,
                                    NewAgility1 =
                                        if
                                            Agility1+500 >= 5000 -> 5000;
                                            true -> Agility1+500
                                        end,

                                    NewR2 =
                                        if
                                            R2+10 >= 40.0 -> 40.0;
                                            true -> R2+10
                                        end,
                                    NewAgility2 =
                                        if
                                            Agility2-500 =< 500 -> 500;
                                            true -> Agility2-500
                                        end,
                                    NewMap1 = maps:update(Key1,[X1,Y1,VX1,VY1,AccelL1,A1,W1,AccelR1,NewR1,NewAgility1,Batteries1,I1],MapPlayers),
                                    NewMap2 = maps:update(Key2,[X2,Y2,VX2,VY2,AccelL2,A2,W2,AccelR2,NewR2,NewAgility2,Batteries2,I2],NewMap1),
                                    maps:update(Key1,generate_safespot(Key1,NewMap2,MapCreatures,ObsList),NewMap2)
                                   
                            end;
                        SumR<Dist -> MapPlayers
                    end;
                true -> MapPlayers
            end;
        _ -> MapPlayers
    end.
    


collision_PlayerCreatures(Player,MapPlayers,Creature,MapCreatures)->
    [X1,Y1,VX,VY,AccelL,A,W,AccelR,R1,Agility1,Batteries1,I] = maps:get(Player,MapPlayers),
    [X2,Y2,_,_,_,_,_,_,R2,_,_,{_,Type}] = maps:get(Creature,MapCreatures),
    SumR = R1+R2,
    XDist = X2-X1,
    YDist = Y2-Y1,
    Dist = math:sqrt((XDist*XDist) + (YDist*YDist)),
    Res = 
        if
        SumR>=Dist -> 
            if
                Type == true ->
                    if
                        R1 =< 10.0 -> 
                            Player! {leave},
                            ?MODULE ! {kill,Player,I},
                            {MapPlayers,maps:remove(Creature,MapCreatures)};
                        true ->
                            ?MODULE ! {killCreature,Creature},
                            NewAgility=
                            if
                                Agility1 - 1000 =< 500 -> 500;
                                true -> Agility1-1000
                            end,
                            {maps:update(Player,[X1,Y1,VX,VY,AccelL,A,W,AccelR,R1,NewAgility,Batteries1,I],MapPlayers),MapCreatures}
                    end;
                true ->
                    
                    GainR = -0.25*R1 + 10,
                    GainAgility = -0.3*Agility1+1500,
                    if
                        R1+GainR >= 40.0 -> NewR = 40;
                        true -> NewR = R1+GainR
                    end,
                    if
                        Agility1+GainAgility >= 5000 -> NewAgility = 5000;
                        true -> NewAgility = Agility1+GainAgility
                    end,

                    ?MODULE ! {killCreature,Creature},
                    {maps:update(Player,[X1,Y1,VX,VY,AccelL,A,W,AccelR,NewR,NewAgility,Batteries1,I],MapPlayers),MapCreatures}
            end;
            
        SumR<Dist -> {MapPlayers,MapCreatures}
    end,
    Res.


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
            [_,_,VX0,VY0,AccelL,A2,W2,AccelR,R2,Agility,Batteries,Type] = maps:get(Key,MapCreatures),
            X = 1100*rand:uniform() + 100,
            Y = 600*rand:uniform() + 100,
            Acc = maps:fold(fun(_,[X1,Y1,_,_,_,_,_,_,_,_,_,_],AccIn) -> AccIn or check_collisionSpawn(X1,Y1,X,Y) end,false,MapPlayers),
            if
                Acc == true -> generate_safespot(Key,MapPlayers,MapCreatures,ObsList);
                true -> 
                    Acc1 = lists:foldl(fun({X1,Y1,_},AccIn) -> AccIn or check_collisionSpawn(X1,Y1,X,Y) end,false,ObsList),
                    if
                        Acc1 == true -> generate_safespot(Key,MapPlayers,MapCreatures,ObsList);
                        true ->
                            Acc2 = maps:fold(fun(_,[X1,Y1,_,_,_,_,_,_,_,_,_,_],AccIn) -> AccIn or check_collisionSpawn(X1,Y1,X,Y) end,false,MapCreatures),
                            if
                                Acc2 == true -> generate_safespot(Key,MapPlayers,MapCreatures,ObsList);
                                true ->
                                    
                                   [X,Y,VX0,VY0,AccelL,A2,W2,AccelR,R2,Agility,Batteries,Type]
                            end
                    end
            end;
            
        false -> 
            [_,_,_,_,_,_,_,_,R1,_,Batteries,I] = maps:get(Key,MapPlayers),
            X = 1100*rand:uniform() + 100,
            Y = 600*rand:uniform() + 100,
                                  
            Acc = maps:fold(fun(_,[X1,Y1,_,_,_,_,_,_,_,_,_,_],AccIn) -> AccIn or check_collisionSpawn(X1,Y1,X,Y) end,false,MapPlayers),
            if
                Acc == true -> generate_safespot(Key,MapPlayers,MapCreatures,ObsList);
                true -> 
                    Acc1 = lists:foldl(fun({X1,Y1,_},AccIn) -> AccIn or check_collisionSpawn(X1,Y1,X,Y) end,false,ObsList),
                    
                    if
                        Acc1 == true -> generate_safespot(Key,MapPlayers,MapCreatures,ObsList);
                        true ->
                             
                            Acc2 = maps:fold(fun(_,[X1,Y1,_,_,_,_,_,_,_,_,_,_],AccIn) -> AccIn or check_collisionSpawn(X1,Y1,X,Y) end,false,MapCreatures),
                            if
                                Acc2 == true -> generate_safespot(Key,MapPlayers,MapCreatures,ObsList);
                                true ->
                                    
                                    [X,Y,0.0,0.0,off,0.0,0.0,off,R1,3000,Batteries,I]
                            end
                    end
            end
        
end.

% ------------------------------------------------------ EVOLVE ------------------------------------------------------ %

evolve(Data,Delta)->
    [X,Y,Vx,Vy,AccelL,A,W,AccelR,R,Agility,Batteries,I] = Data,
    Dt = Delta*(1/1000),
    NewX = X+Vx*Dt,
    NewY = Y+Vy*Dt,
    VMax = 200.0,
    {LBattery,RBattery,MBattery,LState,RState,MState}= Batteries,
    NewMBattery =
        if
        (AccelL == on) and (MState == on) -> 
            Ax = Agility*math:cos(A),
            Ay = Agility*math:sin(A),
            MBattery - 0.3;
        true ->
            Ax = 0.0,Ay = 0.0,
            NewMBattery1 = if 
                MBattery+10*Dt =< 100.0 -> 
                     MBattery+10*Dt;
                true ->  
                    100.0
            end,
            NewMBattery1
    end,

    {NewLBattery,NewRBattery} = 
        if
        (AccelR == left) and (LState == on) -> 
            Alpha = -300,
            {LBattery-2,RBattery};

        (AccelR == left) and (LState == off) -> 
            Alpha = 0,
            NewLBattery1 = 
                if 
                LBattery+10*Dt =< 100.0 -> 
                    LBattery+10*Dt;
                true -> 
                     100.0
            end,
            {NewLBattery1,RBattery};
              
        (AccelR == right) and (RState == on) -> 
            Alpha = 300,
            {LBattery,RBattery-2};

        (AccelR == right) and (RState == off) -> Alpha = 0,
        NewRBattery1 = if 
                RBattery+10*Dt =< 100.0 -> 
                     RBattery+10*Dt;
                true ->  
                    100.0
            end,
            {LBattery,NewRBattery1};
        
        true -> Alpha = 0,
            NewLBattery1 = 
                if 
                LBattery+10*Dt =< 100.0 -> 
                    LBattery+10*Dt;
                true -> 
                     100.0
            end,

            NewRBattery1 = if 
                RBattery+10*Dt =< 100.0 -> 
                     RBattery+10*Dt;
                true ->  
                    100.0
            end,
            {NewLBattery1,NewRBattery1}
    end,



    NewVx = if
        (Vx*0.9)+Ax*Dt >= -0.5*R + VMax -> -0.5*R + VMax;
        (Vx*0.9)+Ax*Dt =< -1*(-0.5*R + VMax) -> -1*(-0.5*R + VMax);
        true -> (Vx*0.9)+Ax*Dt
    end,
    %Velocidade máxima depende do TAMANHO, A agilidade é indepente do tamanho, diminuindo com o tempo até limite minimo
    NewVy = if
        (Vy*0.9)+Ay*Dt >= -0.5*R + VMax -> 
            -0.5*R + VMax;
        (Vy*0.9)+Ay*Dt =<  -1*(-0.5*R + VMax) ->
             -1*(-0.5*R + VMax);
        true -> (Vy*0.9)+Ay*Dt
    end,


    NewA = A+W*Dt,
    NewW = (W*0.65)+Alpha*Dt,
    
    NewR = if 
        R =< 10.0 ->  10.0;
        true ->  R-2*Dt
    end,

    NewAgility = if 
        Agility =< 1000.0 ->  1000.0;
        true ->  Agility-10*Dt
    end,

    
    NewRBatteryState = if 
        (NewRBattery > 15) and (RState == off) ->  on;
        NewRBattery =< 1 -> off;
        true ->  RState
    end,

   NewLBatteryState = if 
        (NewLBattery > 15) and (LState == off) ->  on;
        NewLBattery =< 1 -> off;
        true ->  LState
    end,

    NewMBatteryState = if 
        (NewMBattery > 15) and (MState == off) ->  on;
        NewMBattery =< 1 -> off;
        true ->  MState
    end,

    NewBatteries = {NewLBattery,NewRBattery,NewMBattery,NewLBatteryState,NewRBatteryState,NewMBatteryState},
    [NewX,NewY,NewVx,NewVy,AccelL,NewA,NewW,AccelR,NewR,NewAgility,NewBatteries,I].


evolveCreature(Data,Delta)->
    [X,Y,Vx,Vy,_,_,_,_,R,Agility,Batteries,I] = Data,
    Dt = Delta*(1/1000),
    NewX = X+Vx*Dt,
    NewY = Y+Vy*Dt,
    NewVx = Vx,
    NewVy = Vy,
    [NewX,NewY,NewVx,NewVy,off,0.0,0.0,off,R,Agility,Batteries,I].

accel([X,Y,VX,VY,_,A,W,_,R,Agility,Batteries,I],Move)->
    case lists:member(<<"u">>, Move) of
        true ->
            AccelL = on;
        _ ->
            AccelL = off
    end,
    case lists:member(<<"l">>, Move) of
        true->
            AccelR = left;
        _ ->
            case lists:member(<<"r">>, Move) of
                true->
                    AccelR = right;
                _ ->
                    AccelR = off
            end
    end,
    
[X,Y,VX,VY,AccelL,A,W,AccelR,R,Agility,Batteries,I].
    

sendState(MapPlayers,MapCreatures,Pids,HighScore)->
    List = maps:fold(fun(_,[X,Y,_,_,_,A,_,_,R,_,{LB,RB,B,_,_,_},I],AccIn) -> [integer_to_list(I), io_lib:format("~.3f",[X]),io_lib:format("~.3f",[Y]),io_lib:format("~.3f",[A]),io_lib:format("~.3f",[R]),io_lib:format("~.3f",[LB]),io_lib:format("~.3f",[RB]),io_lib:format("~.3f",[B])    | AccIn] end,[],MapPlayers),
    Sends = maps:keys(MapPlayers),
    String1 = string:join(List," "),
    List2 = maps:fold(fun(_,[X,Y,_,_,_,A,_,_,R,_,_,{I,Type}],AccIn) -> [integer_to_list(I),io_lib:format("~.3f",[X]),io_lib:format("~.3f",[Y]),io_lib:format("~.3f",[A]),io_lib:format("~.3f",[R]),atom_to_list(Type) | AccIn] end,[],MapCreatures),
    String2 =  string:join(List2," "),
    List3 = maps:fold(fun(_,{Username,Score},AccIn) -> [Username,integer_to_list(Score) | AccIn] end,[],Pids),
    String3 =  string:join(List3," "),
    {RecordHolder,HS} = HighScore,
    List4 = [RecordHolder,integer_to_list(HS)],
    String4 =  string:join(List4," "),

    Out = String1 ++ "_Creatures " ++ String2 ++ "_Scores " ++ String3 ++ "_HighScore "  ++ String4,
    Out2 = string:concat(Out,"\r\n"),
    %Send Score 
    [Pid ! {line, Out2} || Pid <- Sends],
    ok.

sendObs(Pid,N,ObsList)->
    List = lists:foldl(fun({X,Y,S},AccIn) -> [io_lib:format("~.3f",[X]),io_lib:format("~.3f",[Y]),io_lib:format("~.3f",[S]) | AccIn]  end,[],ObsList),
    Out = string:join(List," "),
    Out2 = integer_to_list(N) ++ " "++ string:concat(Out,"\r\n"),
    Pid ! {playing, Out2},
    ok.


% -------------------------------------------------- GAME TIME LOOP -------------------------------------------------- %

delta(Delta)->
    receive
        after Delta ->
            ?MODULE ! {run,Delta},
            delta(Delta)
    end.

spawnCreature(Delta) ->
    receive
        after Delta ->
            ?MODULE ! {spawnCreature},
            spawnCreature(Delta)
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
        
        {queued} ->
            gen_tcp:send(Sock,"Q\r\n"),
            user(Sock);
        
        {playing,Msg}->
            gen_tcp:send(Sock, Msg),
            user(Sock);
        
        {leave} ->
            gen_tcp:send(Sock,"RIP\r\n");
        {tcp_closed, _} ->
            print("TCP CLOSED"),
            ?MODULE ! {leave, self()};
        {tcp_error, _, _} ->
            print("TCP ERROR"),
            ?MODULE ! {leave, self()}
    end.

print(String)->
    io:format(String ++ "~n").

createObsList(0)->
    [];
createObsList(N)->
    [newObs()|createObsList(N-1)].

newObs()->
    R = 20.0*rand:uniform()+50.0,
    %io:format("~p~n",[R]),
    {1000*rand:uniform()+200,600*rand:uniform()+100, R}.