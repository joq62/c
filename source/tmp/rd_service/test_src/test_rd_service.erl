%%% -------------------------------------------------------------------
%%% Author  : uabjle
%%% Description : dbase using dets 
%%%
%%% Created : 10 dec 2012
%%% -------------------------------------------------------------------
-module(test_rd_service).
 
%% --------------------------------------------------------------------
%% Include files
%% --------------------------------------------------------------------
-include_lib("eunit/include/eunit.hrl").

%% --------------------------------------------------------------------
-define(POD_ID,["board_w1","board_w2","board_w3"]).
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
    [pod:delete(node(),PodId)||PodId<-?POD_ID],
    A=[pod:create(node(),PodId)||PodId<-?POD_ID],
    Pods=[Pod||{ok,Pod}<-A],
    
    %PodsId=[atom_to_list(Pod)||Pod<-Pods],
    os:cmd("cp -r ebin board_w3/ebin"),
    os:cmd("cp -r src/*.app board_w3/ebin"),
    rpc:call('board_w3@asus',code,add_path,[filename:join("board_w3","ebin")],5000),
    timer:sleep(100),
    os:cmd("cp -r ebin board_w2/ebin"),
    os:cmd("cp -r src/*.app board_w2/ebin"),
    rpc:call('board_w2@asus',code,add_path,[filename:join("board_w2","ebin")],5000),
    timer:sleep(100),
    os:cmd("cp -r ebin board_w1/ebin"),
    os:cmd("cp -r src/*.app board_w1/ebin"),
    rpc:call('board_w1@asus',code,add_path,[filename:join("board_w1","ebin")],5000),
    timer:sleep(100),
    [{Pod,rpc:call(Pod,rd_service,start_link,[])}||Pod<-Pods],
    {ok,_Pid}=rd_service:start_link(),
    ok.

ping_test()->
    TestNode=node(),
    Nodes=nodes(),
    [rpc:call(Node,net_adm,ping,[TestNode])||Node<-Nodes],
    ok.

debug_nodes_test()->
    [test_rd_service@asus,board_w1@asus,board_w2@asus,board_w3@asus]=rd_service:debug(nodes),
    ok.
load_resources_w1_test()->
    Local=[service_1_w1,service_2_w1,service_3_w1],
    Target=[service_1_w2,service_1_w3,service_1_w1],
    [rpc:call('board_w1@asus',rd_service,add_local_resource,[Service,'board_w1@asus'])||Service<-Local],
    [rpc:call('board_w1@asus',rd_service,add_target_resource_type,[Service])||Service<-Target],
    timer:sleep(300),
    ok.

load_resources_w2_test()->
    Local=[service_1_w2,service_2_w2,service_3_w1],
    Target=[service_1_w1,service_1_w3,service_2_w1,service_3_w1],
    [rpc:call('board_w2@asus',rd_service,add_local_resource,[Service,'board_w2@asus'])||Service<-Local],
    [rpc:call('board_w2@asus',rd_service,add_target_resource_type,[Service])||Service<-Target],
    rpc:call('board_w2@asus',rd_service,trade_resources,[]),
    timer:sleep(300),
 
    rpc:call('board_w2@asus',rd_service,debug,[found]),
    {ok,['board_w1@asus','board_w2@asus']}=rpc:call('board_w2@asus',rd_service,fetch_resources,[service_3_w1]),
    error=rpc:call('board_w2@asus',rd_service,fetch_resources,[service_glurk_w1]),
    
    ok.

load_resources_w3_test()->
    Local=[service_1_w3,service_2_w3,service_3_w3],
    Target=[],
    [rpc:call('board_w3@asus',rd_service,add_local_resource,[Service,'board_w3@asus'])||Service<-Local],
    [rpc:call('board_w3@asus',rd_service,add_target_resource_type,[Service])||Service<-Target],
    rpc:call('board_w3@asus',rd_service,trade_resources,[]),
    timer:sleep(300),
    ok.

get_resources_1_test()->
     Local=[],
    Target=[service_1_w2,service_1_w3,service_1_w1,service_1_w2,service_2_w2,service_3_w1,
	    service_1_w3,service_2_w3,service_3_w3],
    [rd_service:add_local_resource(Service,node())||Service<-Local],
    [rd_service:add_target_resource_type(Service)||Service<-Target],
    rd_service:trade_resources(),
    timer:sleep(500),
    R=[{Service,rd_service:fetch_resources(Service)}||Service<-Target],
    [{service_1_w2,{ok,[board_w2@asus]}},
     {service_1_w3,{ok,[board_w3@asus]}},
     {service_1_w1,{ok,[board_w1@asus]}},
     {service_1_w2,{ok,[board_w2@asus]}},
     {service_2_w2,{ok,[board_w2@asus]}},
     {service_3_w1,{ok,[board_w2@asus,board_w1@asus]}},
     {service_1_w3,{ok,[board_w3@asus]}},
     {service_2_w3,{ok,[board_w3@asus]}},
     {service_3_w3,{ok,[board_w3@asus]}}]=R,
    ok.

get_resources_kill_w2_test()->
  %  glurk=rd_service:debug(found),
    pod:delete('board_w2@asus',"board_w2"),
    Target=[service_1_w2,service_1_w3,service_1_w1,service_1_w2,service_2_w2,service_3_w1,
	    service_1_w3,service_2_w3,service_3_w3],
    rpc:call('board_w3@asus',rd_service,trade_resources,[]),
    rpc:call('board_w1@asus',rd_service,trade_resources,[]),
    rpc:call('board_w2@asus',rd_service,trade_resources,[]),
    rd_service:trade_resources(),
    timer:sleep(300),
    R=[{Service,rd_service:fetch_resources(Service)}||Service<-Target],
    [{service_1_w2,error},
     {service_1_w3,{ok,[board_w3@asus]}},
     {service_1_w1,{ok,[board_w1@asus]}},
     {service_1_w2,error},
     {service_2_w2,error},
     {service_3_w1,{ok,[board_w1@asus]}},
     {service_1_w3,{ok,[board_w3@asus]}},
     {service_2_w3,{ok,[board_w3@asus]}},
     {service_3_w3,{ok,[board_w3@asus]}}]=R,
    ok.
	       

stop_test()->
    [pod:delete(node(),PodId)||PodId<-?POD_ID],
    rd_service:stop(),
    do_kill().
do_kill()->
    init:stop().

