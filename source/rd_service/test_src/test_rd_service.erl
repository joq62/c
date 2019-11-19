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
%    rpc:call('board_w1@asus',rd_service,start_link,[]),
 %   glurk=rpc:call('board_w2@asus',rd_service,start_link,[]),
  %  glurk=rpc:call('board_w3@asus',rd_service,start_link,[]),
    [{Pod,rpc:call(Pod,rd_service,start_link,[])}||Pod<-Pods],
    {ok,_Pid}=rd_service:start_link(),
    ok.

load_resources_w1_test()->
    Local=[service_1_w1,service_2_w1,service_3_w1],
    Target=[target_1_w2,target_1_w3],
    [rpc:call('board_w1@asus',rd_service,add_local_resource,[Service,'board_w1@asus'])||Service<-Local],
    rpc:call('board_w1@asus',rd_service,trade_resources,[]),
    rpc:call('board_w1@asus',rd_service,debug,[local]),
    rpc:call('board_w1@asus',rd_service,debug,[found]),
    glurk=rpc:call('board_w1@asus',rd_service,fetch_resources,[service_1_w1]),
    
    ok.

stop_test()->
    [pod:delete(node(),PodId)||PodId<-?POD_ID],
    rd_service:stop(),
    do_kill().
do_kill()->
    init:stop().

