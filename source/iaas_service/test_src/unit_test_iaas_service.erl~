%%% -------------------------------------------------------------------
%%% Author  : uabjle
%%% Description : dbase using dets 
%%%
%%% Created : 10 dec 2012
%%% -------------------------------------------------------------------
-module(unit_test_lib_service). 
  
%% --------------------------------------------------------------------
%% Include files
%% --------------------------------------------------------------------
% -include_lib("eunit/include/eunit.hrl").

%% --------------------------------------------------------------------
-define(SERVER_ID,"test_tcp_server").
%% External exports
-compile(export_all).

-define(TIMEOUT,1000*15).

%% ====================================================================
%% External functions
%% ====================================================================
test()->
    TestList=[init_test,start_container_1_test,start_container_2_test,
	      adder_1_test,adder_2_test,
	      stop_container_1_test,stop_container_2_test,
	      get_node_id_test,
	      init_tcp_test,tcp_1_test,tcp_2_test,
	      end_tcp_test],
    TestR=[{rpc:call(node(),?MODULE,F,[],?TIMEOUT),F}||F<-TestList],
    
    
    Result=case [{error,F,Res}||{Res,F}<-TestR,Res/=ok] of
	       []->
		   ok;
	       ErrorMsg->
		   ErrorMsg
	   end,
    Result.
	


%% --------------------------------------------------------------------
%% Function:init 
%% Description:
%% Returns: non
%% --------------------------------------------------------------------
init_test()->
 %   ok=application:start(lib_service),
    Pod=misc_lib:get_node_by_id("pod_adder_1"),
    container:delete(Pod,"pod_adder_1",["adder_service"]),
    pod:delete(node(),"pod_adder_1"),
    container:delete(Pod,"pod_adder_2",["adder_service"]),
    pod:delete(node(),"pod_adder_2"),
    ok.
    
%------------------ ceate and delete Pods and containers -------
%create_container(Pod,PodId,[{{service,ServiceId},{Type,Source}}

start_container_1_test()->
    {ok,PodAdder}=pod:create(node(),"pod_adder_1"),
    ok=container:create(PodAdder,"pod_adder_1",
			[{{service,"adder_service"},
			  {dir,"/home/pi/erlang/c/source"}}
			]),
   ok.

start_container_2_test()->
    {ok,PodAdder}=pod:create(node(),"pod_adder_2"),
    ok=container:create(PodAdder,"pod_adder_2",
			[{{service,"adder_service"},
			  {dir,"/home/pi/erlang/c/source"}}
			]),
   ok.
adder_1_test()->
    Pod=misc_lib:get_node_by_id("pod_adder_1"),
    42=rpc:call(Pod,adder_service,add,[20,22]),
    ok.

adder_2_test()->
    Pod=misc_lib:get_node_by_id("pod_adder_2"),
    142=rpc:call(Pod,adder_service,add,[120,22]),
    ok.

stop_container_1_test()->
    Pod=misc_lib:get_node_by_id("pod_adder_1"),
    container:delete(Pod,"pod_adder_1",["adder_service"]),
   % timer:sleep(500),
    {ok,stopped}=pod:delete(node(),"pod_adder_1"),
    ok.

stop_container_2_test()->
    Pod=misc_lib:get_node_by_id("pod_adder_2"),
    container:delete(Pod,"pod_adder_2",["adder_service"]),
  %  timer:sleep(500),
    {ok,stopped}=pod:delete(node(),"pod_adder_2"),
    ok.

%------------------------------------------------------------
get_node_id_test()->
    {ok,Host}=inet:gethostname(),
    PodIdServer=?SERVER_ID++"@"++Host,
    PodServer=list_to_atom(PodIdServer),
    PodServer=misc_lib:get_node_by_id(?SERVER_ID), 
    ok.




%**************************** tcp test   ****************************
init_tcp_test()->
    pod:delete(node(),"pod_lib_1"),
    pod:delete(node(),"pod_lib_2"),
    {ok,Pod_1}=pod:create(node(),"pod_lib_1"),
    ok=container:create(Pod_1,"pod_lib_1",
			[{{service,"lib_service"},
			  {dir,"/home/pi/erlang/c/source"}}
			]),    
    {ok,Pod_2}=pod:create(node(),"pod_lib_2"),
    ok=container:create(Pod_2,"pod_lib_2",
			[{{service,"lib_service"},
			  {dir,"/home/pi/erlang/c/source"}}
			]),    
    ok.

tcp_1_test()->
    PodServer=misc_lib:get_node_by_id("pod_lib_1"),
    PodClient=misc_lib:get_node_by_id("pod_lib_2"),
    _Pid=rpc:call(PodServer,tcp_server,start_seq_server,[1234]),
    D=date(),
    Result=rpc:call(PodClient,tcp_client,call,[{"localhost",1234},PodServer,{erlang,date,[]}]),
    D=Result,
    D=rpc:call(PodClient,tcp_client,call,[{"localhost",1234},{erlang,date,[]}]),
    D=tcp_client:call({"localhost",1234},{erlang,date,[]}),
    
    ok.

tcp_2_test()->
    PodServer=misc_lib:get_node_by_id("pod_lib_1"),
    _PodClient=misc_lib:get_node_by_id("pod_lib_2"),
    _Pid=rpc:call(PodServer,tcp_server,start_seq_server,[1234]),

    PidSession=tcp_client:connect("localhost",1234),
   % tcp_client:session_call(PidSession,{erlang,date,[]}),
    loop_send(1000,PidSession),
    _R1=loop_get(1000,PidSession,[]),
    loop_send2(1000,PidSession,PodServer),
    _R2=loop_get(1000,PidSession,[]),
    tcp_client:disconnect(PidSession),
    ok.
    
loop_send2(0,_,_)->
    ok;
loop_send2(N,PidSession,Pod) ->
    tcp_client:session_call(PidSession,{erlang,date,[]}),
    loop_send2(N-1,PidSession,Pod).
loop_send(0,_)->
    ok;
loop_send(N,PidSession) ->
    tcp_client:session_call(PidSession,{erlang,date,[]}),
    loop_send(N-1,PidSession).
loop_get(0,_PidSession,Result)->
    Result;
loop_get(N,PidSession,Acc) ->
    loop_get(N-1,PidSession,[{N,tcp_client:get_msg(PidSession,2000)}|Acc]).
    
end_tcp_test()->
    container:delete('pod_lib_1@asus.com',"pod_adder_1",["lib_service"]),
    {ok,stopped}=pod:delete(node(),"pod_lib_1"),
    container:delete('pod_lib_2@asus.com',"pod_adder_2",["lib_service"]),
    {ok,stopped}=pod:delete(node(),"pod_lib_2"),
    ok.


%**************************************************************
