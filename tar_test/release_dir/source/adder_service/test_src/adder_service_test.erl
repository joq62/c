%%% -------------------------------------------------------------------
%%% Author  : uabjle
%%% Description : dbase using dets 
%%%
%%% Created : 10 dec 2012
%%% -------------------------------------------------------------------
-module(adder_service_test). 
  
%% --------------------------------------------------------------------
%% Include files
%% --------------------------------------------------------------------
% -include_lib("eunit/include/eunit.hrl").
-include("test_src/common_macros.hrl").
%% --------------------------------------------------------------------

%% External exports
-export([test/0,init_test/0,
	 start_adder/0,
	 adder_1_test/0,
	 adder_2_test/0,
	 cleanup/0
	]).
	 
%-compile(export_all).


%% ====================================================================
%% External functions
%% ====================================================================
-define(TIMEOUT,1000*15).
test()->
    io:format("~p~n",[{?MODULE,?LINE}]),
    TestList=[
	      init_test,
	      start_adder,
	      adder_1_test,
	    %  adder_2_test,
	      cleanup 
	     ],
    test_support:execute(TestList,?MODULE,?TIMEOUT).		

 
%% --------------------------------------------------------------------
%% Function:init 
%% Description:
%% Returns: non
%% --------------------------------------------------------------------
init_test()->
   % pod:delete(node(),"pod_master"),
   % timer:sleep(100),
    pod:delete(node(),"pod_adder_1"),
   % timer:sleep(100),
    Pod=tcp_client:call(?DNS_ADDRESS,{erlang,node,[]}),
    {pong,Pod,lib_service}=tcp_client:call(?DNS_ADDRESS,{lib_service,ping,[]}),
    {pong,Pod,dns_service}=tcp_client:call(?DNS_ADDRESS,{dns_service,ping,[]}),
    ok.
    
%------------------  -------
%create_container(Pod,PodId,[{{service,ServiceId},{Type,Source}}

start_adder()->
    
    {ok,Pod1}=pod:create(node(),"pod_adder_1"),
    ok=container:create(Pod1,"pod_adder_1",
			[{{service,"lib_service"},
			  {dir,"/home/pi/erlang/c/source"}}
			]), 
    ok=rpc:call(Pod1,lib_service,start_tcp_server,["localhost",50001,parallell],2000),
    ok=container:create(Pod1,"pod_adder_1",
			[{{service,"adder_service"},
			  {dir,"/home/pi/erlang/c/source"}}
			]),   

    % start on test node
    ok=rpc:call(node(),lib_service,start_tcp_server,["localhost",50000,parallell],2000),
 
    {pong,_,lib_service}=tcp_client:call({"localhost",50000},{lib_service,ping,[]}),
    {"localhost",50000}=tcp_client:call({"localhost",50000},{lib_service,myip,[]}),
     {pong,_,adder_service}=tcp_client:call({"localhost",50000},{adder_service,ping,[]}),
    ok.

adder_1_test()->
    %glurk=?DNS_ADDRESS,
    42=tcp_client:call({"localhost",50000},{adder_service,add,[20,22]}),
    43=tcp_client:call({"localhost",50001},{adder_service,add,[20,23]}),

    ok.


adder_2_test()->
    % expired test   
    ok.

cleanup()->
    {ok,stopped}=rpc:call(node(),lib_service,stop_tcp_server,["localhost",50000],2000),
    {ok,stopped}=rpc:call(misc_lib:get_node_by_id("pod_adder_1"),lib_service,stop_tcp_server,["localhost",50001],2000),
    {ok,stopped}=pod:delete(node(),"pod_adder_1"),   
    ok.


%**************************************************************
