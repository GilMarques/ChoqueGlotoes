-module(login).




start() ->
    Pid = spawn(fun()-> loop() end),
    ok.


loop()->
    ok.

stop()->
    ok.