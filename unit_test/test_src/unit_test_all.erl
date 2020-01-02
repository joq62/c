%%% -------------------------------------------------------------------
%%% Author  : uabjle
%%% Description : dbase using dets 
%%%
%%% Created : 10 dec 2012
%%% -------------------------------------------------------------------
-module(unit_test_all). 
 
%% --------------------------------------------------------------------
%% Include files
%% --------------------------------------------------------------------


%% --------------------------------------------------------------------

%% External exports

-export([start/0]).


%% ====================================================================
%% External functions
%% ====================================================================
%% --------------------------------------------------------------------
%% Function:init 
%% Description:
%% Returns: non
%% --------------------------------------------------------------------

-define(UNIT_TEST_SPEC,"unit_test_all.spec").

start()->
    
    % Each unit test creates its own test vms
    % load lib_service + application to test
    % {{service2test,"lib_service"},{src_dir,"/home/pi/erlang/c/source"},
    %  {test_module,unit_test_lib_service},{preload,[]}}
    % Create pod to load application to test
    PodId="pod_test_1",
    pod:delete(node(),PodId),
    {ok,Pod}=pod:create(node(),PodId),
    {ok,I}=file:consult(?UNIT_TEST_SPEC),
    Result=do_unit_test(I,Pod,PodId,[]),
    io:format(" ~n"),
    io:format("~p ",[time()]),
    io:format(": Result ~n"),
    [io:format("~p~n",[R])||R<-Result],
    io:format(" ~n"),
    pod:delete(node(),PodId),
    init:stop(),
    ok.

    
%% --------------------------------------------------------------------
%% Function:init 
%% Description:
%% Returns: non
%% --------------------------------------------------------------------
do_unit_test([],_Pod,_PodId,Result)->
    Result;
do_unit_test([Info|T],Pod,PodId,Acc) ->
    {{service2test,ServiceId},{src_dir,Source},
     {test_module,TestModule},{preload,_Applications}}=Info,
    io:format(" ~n"),
    io:format("~p",[time()]),
    io:format(": Testing  ~p~n",[ServiceId]),
    io:format(" ~n"),
  %   io:format("ping  ~p~n",[{net_adm:ping(Pod)}]),
    ok=container:create(Pod,PodId,
			[{{service,ServiceId},
			  {dir,Source}}
			]),
    R=rpc:call(Pod,TestModule,test,[]),
    io:format("Test result  ~p~n",[{R,ServiceId}]),
   % io:format("delete conatiern   ~p~n",[{Pod,PodId,[ServiceId]}]),
    container:delete(Pod,PodId,[ServiceId]),
    do_unit_test(T,Pod,PodId,[{R,ServiceId}|Acc]).

%% --------------------------------------------------------------------
%% Function:init 
%% Description:
%% Returns: non
%% --------------------------------------------------------------------

%create_dir()->
        % Use date and time 
 %   timer:sleep(1200), % Secure that there is a new directory becaus o second resolution
 %   {{Y,M,D},{H,Min,S}}={date(),time()},
 %   Time=string:join([integer_to_list(H),integer_to_list(Min),integer_to_list(S)],":"),
 %   Date=string:join([integer_to_list(Y),integer_to_list(M),integer_to_list(D)],"-"),
 %   DirName=string:join([Time,Date,"test_dir"],"_"),
 %   file:make_dir(DirName),
 %   DirName.

%----------------------------------------------
%start_service(Node,PodId,ListOfServices)->
%    case pod:create(Node,PodId) of
%	{error,Err}->
%	    io:format(" ~p~n~n",[{error,Err}]);
%	{ok,Pod}->
%	    ok=container:create(Pod,PodId,ListOfServices)
%    end.
    
%stop_service(Node,PodId,ListOfServices)->
 %   {ok,Host}=rpc:call(Node,inet,gethostname,[]),
  %  PodIdServer=PodId++"@"++Host,
   % Pod=list_to_atom(PodIdServer),
  %  container:delete(Pod,PodId,ListOfServices),
  %  {ok,stopped}=pod:delete(Node,PodId).
