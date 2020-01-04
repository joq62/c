%%% -------------------------------------------------------------------
%%% Author  : uabjle
%%% Description : dbase using dets 
%%%
%%% Created : 10 dec 2012
%%% -------------------------------------------------------------------
-module(unit_test). 
 
%% --------------------------------------------------------------------
%% Include files
%% --------------------------------------------------------------------
-include("common_macros.hrl").

%% --------------------------------------------------------------------
-ifdef(local).
-define(LIB_SERVICE_SRC,{dir,"/home/pi/erlang/c/source"}).
-endif.
-ifdef(private).
-define(LIB_SERVICE_SRC,{dir,"/home/pi/erlang/c/source"}).
-endif.
-ifdef(public).
-define(LIB_SERVICE_SRC,{url,path_to_github}).
-endif.
%% External exports

-export([start/0,start/1]).


%% ====================================================================
%% External functions
%% ====================================================================
%% --------------------------------------------------------------------
%% Function:init 
%% Description:
%% Returns: non
%% --------------------------------------------------------------------

-define(TEST_SPEC,"unit_test.spec").

start()->
    start(?TEST_SPEC).
start(TestSpec)->
    
    % Each unit test creates its own test vms
    % load lib_service + application to test
    % {{service2test,"lib_service"},{src_dir,"/home/pi/erlang/c/source"},
    %  {test_module,unit_test_lib_service},{preload,[]}}
    % Create pod to load application to test
    PodId="pod_test_1",
    pod:delete(node(),"pod_dns_test"),
    pod:delete(node(),PodId),
    {ok,Pod}=pod:create(node(),PodId),
    {ok,I}=file:consult(TestSpec),
 %   Pod=node(),
  %  [PodId,_Host]=string:split(atom_to_list(node()),"@"), 
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
     {test_module,TestModule},{preload,_PreLoad}}=Info,
    io:format(" ~n"),
    io:format("~p",[time()]),
    io:format(": Testing  ~p~n",[TestModule]),
    io:format(" ~n"),
    if 
	ServiceId/="lib_service"->
	    ok=container:create(Pod,PodId,
				[{{service,"lib_service"},
				  ?LIB_SERVICE_SRC}
				]),
	    if 
		ServiceId/="dns_service"->
		    {ok,DnsTest}=pod:create(node(),"pod_dns_test"),
		    ok=container:create(DnsTest,"pod_dns_test",
					[{{service,"lib_service"},
					  ?LIB_SERVICE_SRC}
					]),
		    ok=container:create(DnsTest,"pod_dns_test",
					[{{service,"dns_service"},
					  {dir,"/home/pi/erlang/c/source"}}
					]),    
		    ok=rpc:call(DnsTest,lib_service,start_tcp_server,[?DNS_ADDRESS,parallell]);
		true->
		    ok
	    end;
	true->
	    ok
    end,
    ok=container:create(Pod,PodId,
			[{{service,ServiceId},
			  {dir,Source}}
			]),
    R={rpc:call(Pod,TestModule,test,[],2*60*1000),ServiceId,TestModule,?MODULE,?LINE},
    io:format("Test result  ~p~n",[R]),
    if 
	ServiceId/="dns_service"->
	    PodDns2=misc_lib:get_node_by_id("pod_dns_test"),
	    rpc:call(PodDns2,lib_service,stop_tcp_server,[?DNS_ADDRESS]),
	    container:delete(PodDns2,"pod_dns_test",["dns_service"]),
	    pod:delete(node(),"pod_dns_test");
        true->
	    ok
    end, 
    container:delete(Pod,PodId,["lib_service"]),
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
