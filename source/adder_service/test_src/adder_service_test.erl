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
    TestList=[init_test,
	      start_adder,
	      adder_1_test,
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
    %
    %glurk=rpc:call(Pod1,lib_service,ping,[]),
    ok=rpc:call(Pod1,lib_service,start_tcp_server,["localhost",50000,parallell],2000),
    timer:sleep(100),
    {pong,_,lib_service}=tcp_client:call({"localhost",50000},{lib_service,ping,[]}),
    {"localhost",50000}=tcp_client:call({"localhost",50000},{lib_service,myip,[]}),
  %  glurk=tcp_client:call({"localhost",50000},{lib_service,myip,[]}),
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
    glurk=?DNS_ADDRESS,
    Y=tcp_client:call(?DNS_ADDRESS,{dns_service,get,["adder_service"]}),
    glurk=Y,
    ok.


adder_2_test()->
    % expired test   
    ok.



cleanup()->
    {ok,stopped}=pod:delete(node(),"pod_adder_1"),   
    ok.


%**************************************************************
