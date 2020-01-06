%%% -------------------------------------------------------------------
%%% Author  : uabjle
%%% Description : dbase using dets 
%%%
%%% Created : 10 dec 2012
%%% -------------------------------------------------------------------
-module(test_iaas_service).
 
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
    Pods=[pod:create(node(),PodId)||PodId<-?POD_ID],
    
  %  glurk=nodes_config:init("nodes.config"),
    {ok,_Pid}=iaas_service:start(),
    undefined=iaas_service:active_boards(),
    ok.

boards_1_test()->
    timer:sleep(2000),
    {ok,["board_w3@asus",
	 "board_m1@asus",
	 "board_w1@asus",
	 "board_w2@asus",
	 "board_m2@asus"]}=iaas_service:get_all_nodes(),
    ok.
boards_2_test()->
    ["board_w3@asus","board_w1@asus","board_w2@asus"]=iaas_service:active_boards(),
    ["board_m1@asus","board_m2@asus"]=iaas_service:inactive_boards(),
    ok.


stop_test()->
    [pod:delete(node(),PodId)||PodId<-?POD_ID],
    iaas_service:stop(),
    do_kill().
do_kill()->
    init:stop().

