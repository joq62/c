%%% -------------------------------------------------------------------
%%% Author  : uabjle
%%% Description : dbase using dets 
%%%
%%% Created : 10 dec 2012
%%% -------------------------------------------------------------------
-module(adder_unit_test). 
  
%% --------------------------------------------------------------------
%% Include files
%% --------------------------------------------------------------------
% -include_lib("eunit/include/eunit.hrl").

%% --------------------------------------------------------------------

%% External exports
-export([test/0,init_test/0,
	 start_adder_test/0,
	 adder_1_test/0,
	 adder_2_test/0,
	 stop_adder_test/0
	]).
	 
%-compile(export_all).

-define(TIMEOUT,1000*15).

%% ====================================================================
%% External functions
%% ====================================================================
test()->
    TestList=[init_test,
	      start_adder_test,
	      adder_1_test,
	      adder_2_test,
	      stop_adder_test 
	     ],
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
   
    ok.
    
%------------------  -------
%create_container(Pod,PodId,[{{service,ServiceId},{Type,Source}}

start_adder_test()->
    {ok,Pod}=pod:create(node(),"pod_adder_1"),
     ok=container:create(Pod,"pod_adder_1",
			[{{service,"adder_service"},
			  {dir,"/home/pi/erlang/c/source"}}
			]),
    ok=container:create(Pod,"pod_adder_1",
			[{{service,"lib_service"},
			  {dir,"/home/pi/erlang/c/source"}}
			]),
    ok=container:create(Pod,"pod_adder_1",
			[{{service,"adder_service"},
			  {dir,"/home/pi/erlang/c/source"}}
			]),
   
   ok.

adder_1_test()->
    {DnsIpAddr,DnsPort}=lib_service:dns_address(),
    glurk=tcp_client:call({DnsIpAddr,DnsPort},{dns_service,ping,[]}),
    
    
    ok.


adder_2_test()->
    % expired test
   
    ok.



stop_adder_test()->
    Pod=misc_lib:get_node_by_id("pod_adder_1"),
    container:delete(Pod,"pod_adder_1",["dns_service"]),
    container:delete(Pod,"pod_adder_1",["adder_service"]),
    {ok,stopped}=pod:delete(node(),"pod_adder_1"),
    ok.


%**************************************************************
