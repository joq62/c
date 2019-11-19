%%% -------------------------------------------------------------------
%%% Author  : uabjle
%%% Description : dbase using dets 
%%%
%%% Created : 10 dec 2012
%%% -------------------------------------------------------------------
-module(test_master_service).
 
%% --------------------------------------------------------------------
%% Include files
%% --------------------------------------------------------------------
-include_lib("eunit/include/eunit.hrl").

%% --------------------------------------------------------------------
-define(W1,'worker_1@asus').
-define(W2,'worker_2@asus').
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
  %  glurk=nodes_config:init("nodes.config"),
    {ok,_Pid}=master_service:start(),
    ok.

nodes_config_zone_test()->
{ok,[{"board_w3@asus","sthlm.flat.balcony"},
     {"board_w1@asus","varmdoe.main.room2"},
     {"board_w2@asus","varmdoe.guesthouse.room1"},
     {"board_m1@asus","sthlm.flat.room1"},
     {"board_m2@asus","varmdoe.main.room1"}]}=master_service:zone(),
    {ok,"varmdoe.guesthouse.room1"}=master_service:zone('board_w2@asus'),
    {error,[no_zones,nodes_config,_Line]}=master_service:zone('glurk@asus'),
    ok.    

nodes_config_ip_addr_test()->
    {ok,[{"localhost",20030}]}=master_service:ip_addr("board_w3@asus"),
    {ok,["board_w3@asus"]}=master_service:ip_addr("localhost",20030),
    {error,[eexist,"glurk@asus",nodes_config,_]}=master_service:ip_addr("glurk@asus"),
    {error,[eexists,"localhost",202230,nodes_config,_]}=master_service:ip_addr("localhost",202230),
    ok.

nodes_config_capa_test()->
    {ok,[{"board_m1@asus",tellstick}]}=master_service:capability(tellstick),
    {ok,[{"board_w3@asus",disk},{"board_m1@asus",disk}]}=master_service:capability(disk),
    {ok,[]}=master_service:capability(glurk),
    ok.

    
stop_test()->
    master_service:stop(),
    do_kill().
do_kill()->
    init:stop().
