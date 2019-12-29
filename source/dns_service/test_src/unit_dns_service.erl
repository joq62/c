%%% -------------------------------------------------------------------
%%% Author  : uabjle
%%% Description : dbase using dets 
%%%
%%% Created : 10 dec 2012
%%% -------------------------------------------------------------------
-module(unit_dns_service). 
  
%% --------------------------------------------------------------------
%% Include files
%% --------------------------------------------------------------------
% -include_lib("eunit/include/eunit.hrl").

%% --------------------------------------------------------------------
-define(SERVER_ID,"test_tcp_server").
%% External exports
-compile(export_all).

-define(TIMEOUT,1000*15).

%% ====================================================================
%% External functions
%% ====================================================================
test()->
    TestList=[init_test,start_dns_test,dns_1_test,
	      stop_dns_test,stop_test],
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

start_dns_test()->
    {ok,Pod}=pod:create(node(),"pod_dns_1"),
    ok=container:create(Pod,"pod_dns_1",
			[{{service,"lib_service"},
			  {dir,"/home/pi/erlang/c/source"}}
			]),
     ok=container:create(Pod,"pod_dns_1",
			[{{service,"dns_service"},
			  {dir,"/home/pi/erlang/c/source"}}
			]),
   
   ok.

dns_1_test()->
    dns_service:add("s1","IpAddr1",1000,vm1),
    io:format("~p~n",[{dns_service:all(),?MODULE,?LINE}]),
    io:format("~p~n",[{dns_service:get("s1"),?MODULE,?LINE}]),
    dns_service:add("s1","IpAddr1",1001,vm1),
    dns_service:add("s1","IpAddr2",1001,vm1),
    dns_service:add("s1","IpAddr1",1000,vm2),
    dns_service:add("s2","IpAddr1",1000,vm3),
    io:format("~p~n",[{dns_service:all(),?MODULE,?LINE}]),
    io:format("~p~n",[{dns_service:get("s1"),?MODULE,?LINE}]),
    io:format("~p~n",[{dns_service:get("s2"),?MODULE,?LINE}]),
    timer:sleep(2000),
    dns_service:add("s2","IpAddr1",1000,vm3),
 %   io:format("~p~n",[{dns_service:get("s2"),?MODULE,?LINE}]),
 %   io:format("~p~n",[{dns_service:all(),?MODULE,?LINE}]),
    io:format("~p~n",[{dns_lib:expired(),?MODULE,?LINE}]),
    io:format("~p~n",[{dns_service:all(),?MODULE,?LINE}]),
  
    
    ok.



stop_dns_test()->
    Pod=misc_lib:get_node_by_id("pod_dns_1"),
    container:delete(Pod,"pod_dns_1",["dns_service"]),
    {ok,stopped}=pod:delete(node(),"pod_dns_1"),
    ok.


%**************************************************************
stop_test()->
    init:stop(),
    ok.
