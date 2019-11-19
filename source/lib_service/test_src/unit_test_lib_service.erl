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
-include_lib("eunit/include/eunit.hrl").

%% --------------------------------------------------------------------
-define(SERVER_ID,"test_tcp_server").
%% External exports

-export([]).


%% ====================================================================
%% External functions
%% ====================================================================
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

%**************************** tcp test   ****************************

    
%-----------------------------------------------------------------------------
start_container_1_test()->
    {ok,PodAdder}=pod:create(node(),"pod_adder_1"),
    ok=container:create(PodAdder,"pod_adder_1",[{"adder_service",[]}]),
   ok.

start_container_2_test()->
    {ok,PodAdder}=pod:create(node(),"pod_adder_2"),
    ok=container:create(PodAdder,"pod_adder_2",[{"adder_service",[]}]),
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

%**************************************************************
stop_test()->
    init:stop(),
    ok.
