%%% -------------------------------------------------------------------
%%% Author  : uabjle
%%% Description : dbase using dets 
%%%
%%% Created : 10 dec 2012
%%% -------------------------------------------------------------------
-module(unit_test_nodes).  
 
%% --------------------------------------------------------------------
%% Include files
%% --------------------------------------------------------------------
-include_lib("eunit/include/eunit.hrl").

%% --------------------------------------------------------------------
-define(ID_NODE1,"node1").
-define(ID_NODE2,"node2").
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
start_container_1_test()->
    {ok,PodAdder}=pod:create(node(),"pod_adder_1"),
    [{ok,"adder_service"}]=container:create(PodAdder,"pod_adder_1",["adder_service"]),
   ok.

start_container_2_test()->
    {ok,PodAdder}=pod:create(node(),"pod_adder_2"),
    [{ok,"adder_service"}]=container:create(PodAdder,"pod_adder_2",["adder_service"]),
   ok.

adder_1_test()->
    Pod=get_node("pod_adder_1"),
    42=rpc:call(Pod,adder_service,add,[20,22]),
    ok.

adder_2_test()->
    Pod=get_node("pod_adder_2"),
    142=rpc:call(Pod,adder_service,add,[120,22]),
    ok.

stop_container_1_test()->
    Pod=get_node("pod_adder_1"),
    container:delete(Pod,"pod_adder_1",["adder_service"]),
    {ok,stopped}=pod:delete(node(),"pod_adder_1"),
    ok.

stop_container_2_test()->
    Pod=get_node("pod_adder_2"),
    container:delete(Pod,"pod_adder_2",["adder_service"]),
    {ok,stopped}=pod:delete(node(),"pod_adder_2"),
    ok.

stop_test_XX()->
    Node1=get_node(?ID_NODE1),
    rpc:call(Node1,init,stop,[]),
    rpc:call(get_node("adder_pod"),init,stop,[]),
    os:cmd("rm -rf "++"adder_pod"),
    timer:sleep(1000),
    os:cmd("rm -rf "++"node1"),
    timer:sleep(1000),
 %   Node1=get_node(?ID_NODE1),
 %   {ok,stopped}=stop_erl_node:stop_node(Node1,?ID_NODE1),
    %stop_erl_node:stop_node(node(),"adder_pod"),

    ok.


get_node(Id)->
    {ok,Host}=inet:gethostname(),
    list_to_atom(Id++"@"++Host).
