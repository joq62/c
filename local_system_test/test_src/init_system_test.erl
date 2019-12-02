%%% -------------------------------------------------------------------
%%% Author  : uabjle
%%% Description : dbase using dets 
%%%
%%% Created : 10 dec 2012
%%% -------------------------------------------------------------------
-module(init_system_test). 
 
%% --------------------------------------------------------------------
%% Include files
%% --------------------------------------------------------------------


%% --------------------------------------------------------------------
-define(TEST_BOARDS_CONF,"test_boards.conf").


%% External exports

-export([start/0,stop/0]).


%% ====================================================================
%% External functions
%% ====================================================================
%% --------------------------------------------------------------------
%% Function:init 
%% Description:
%% Returns: non
%% --------------------------------------------------------------------
start()->
    % Check if all test nodes are running
    {ok,I}=file:consult(?TEST_BOARDS_CONF),
    
    [pod:delete(node(),PodId)||PodId<-I],
    A=[pod:create(node(),PodId)||PodId<-I],
    Pods=[Pod||{ok,Pod}<-A],
    
    ok=ping_test(),    
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
    io:format("started test nodes = ~p~n",[nodes()]),
    
    ok.

ping_test()->
    TestNode=node(),
    Nodes=nodes(),
    [rpc:call(Node,net_adm,ping,[TestNode])||Node<-Nodes],
    ok.


%% --------------------------------------------------------------------
%% Function:init 
%% Description:
%% Returns: non
%% --------------------------------------------------------------------
stop()->
    {ok,I}=file:consult(?TEST_BOARDS_CONF),
    [pod:delete(node(),PodId)||PodId<-I],
    io:format("test nodes after stop = ~p~n",[nodes()]),
    do_kill().
do_kill()->
    init:stop().


%% --------------------------------------------------------------------
%% Function:init 
%% Description:
%% Returns: non
%% --------------------------------------------------------------------
