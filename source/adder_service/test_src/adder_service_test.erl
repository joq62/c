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

%% --------------------------------------------------------------------

%% External exports
-export([test/0,init_test/0,
	 start_master_adder/0,
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
    TestList=[init_test,
	      start_master_adder,
	    %  adder_1_test,
	    %  adder_2_test,
	      cleanup 
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
   % pod:delete(node(),"pod_master"),
   % timer:sleep(100),
   % pod:delete(node(),"pod_adder_1"),
   % timer:sleep(100),
    application:start(lib_service),
    ok.
    
%------------------  -------
%create_container(Pod,PodId,[{{service,ServiceId},{Type,Source}}

start_master_adder()->
    {ok,PodMaster}=pod:create(node(),"pod_master"),
    ok=container:create(PodMaster,"pod_master",
			[{{service,"lib_service"},
			  {dir,"/home/pi/erlang/c/source"}}
			]), 
 %   timer:sleep(100),
    ok=container:create(PodMaster,"pod_master",
			[{{service,"dns_service"},
			  {dir,"/home/pi/erlang/c/source"}}
			]), 
  %  timer:sleep(100),
    {DnsIpAddr,DnsPort}=lib_service:dns_address(),   
    {pong,_,_}=rpc:call(PodMaster,lib_service,ping,[],2000),
    {pong,_,_}=rpc:call(PodMaster,dns_service,ping,[],2000),
    {"localhost",42000}={DnsIpAddr,DnsPort},
    ok=rpc:call(PodMaster,lib_service,start_tcp_server,[DnsIpAddr,DnsPort,parallell],2000),
   % ok=rpc:call(PodMaster,lib_service,start_tcp_server,["localhost",42000,parallell],2000),
  %  {pong,_,dns_service}=tcp_client:call({DnsIpAddr,DnsPort},{dns_service,ping,[]}),

    {ok,Pod1}=pod:create(node(),"pod_adder_1"),
    ok=container:create(Pod1,"pod_adder_1",
			[{{service,"lib_service"},
			  {dir,"/home/pi/erlang/c/source"}}
			]), 
    %timer:sleep(100),
    ok=rpc:call(Pod1,lib_service,start_tcp_server,["localhost",50000,parallell],2000),
    {pong,_,lib_service}=tcp_client:call({"localhost",50000},{lib_service,ping,[]}),
    ok=container:create(Pod1,"pod_adder_1",
			[{{service,"adder_service"},
			  {dir,"/home/pi/erlang/c/source"}}
			]),
    %timer:sleep(100),
    A=rpc:call(Pod1,adder_service,start_result,[],2000),
    io:format("star_result ~p~n",[A]),
    {pong,_,adder_service}=tcp_client:call({"localhost",50000},{adder_service,ping,[]}),


   ok.

adder_1_test()->
    {DnsIpAddr,DnsPort}=lib_service:dns_address(),
    glurk=tcp_client:call({DnsIpAddr,DnsPort},{dns_service,ping,[]}),
    
    
    ok.


adder_2_test()->
    % expired test
   
    ok.



cleanup()->
    {ok,stopped}=pod:delete(node(),"pod_adder_1"),   
    {ok,stopped}=pod:delete(node(),"pod_master"),
    ok.


%**************************************************************
