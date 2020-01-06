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

%% External exports
-export([test/0,
	 init_test/0,start_dns_test/0,
	 dns_1_test/0,dns_2_test/0,
	 stop_dns_test/0
	]).
	 
%-compile(export_all).

-define(TIMEOUT,1000*15).

%% ====================================================================
%% External functions
%% ====================================================================
test()->
    TestList=[init_test,start_dns_test,dns_1_test,
	      dns_1_test,dns_2_test,
	      stop_dns_test 
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
    {pong,_,dns_service}=dns_service:ping(),
    ok.
    
%------------------  -------
%create_container(Pod,PodId,[{{service,ServiceId},{Type,Source}}

start_dns_test()->
    {ok,Pod}=pod:create(node(),"pod_dns_1"),
     ok=container:create(Pod,"pod_dns_1",
			[{{service,"dns_service"},
			  {dir,"/home/pi/erlang/c/source"}}
			]),
    ok=container:create(Pod,"pod_dns_1",
			[{{service,"lib_service"},
			  {dir,"/home/pi/erlang/c/source"}}
			]),
   
   ok.

dns_1_test()->
    % add,delete, all

    dns_service:add("s1","IpAddr1",1000,vm1),
    timer:sleep(50),
    [{"s1","IpAddr1",1000,vm1,_}]=dns_service:all(),
    [["IpAddr1",1000,vm1]]=dns_service:get("s1"),
    % duplicate test
    dns_service:add("s1","IpAddr1",1000,vm1),
    timer:sleep(50),
    [{"s1","IpAddr1",1000,vm1,_}]=dns_service:all(),
    [["IpAddr1",1000,vm1]]=dns_service:get("s1"),
    % delete test
    dns_service:delete("s1","IpAddr1",1000,vm1),
    timer:sleep(50),
    []=dns_service:all(),
    []=dns_service:get("s1"),
    dns_service:clear(),
    ok.


dns_2_test()->
    % expired test
    dns_service:add("s1","IpAddr1",1000,vm1),
    timer:sleep(50),
    [["IpAddr1",1000,vm1]]=dns_service:get("s1"),
    dns_service:add("s1","IpAddr1",1001,vm1),
    dns_service:add("s1","IpAddr2",1001,vm1),
    dns_service:add("s1","IpAddr1",1000,vm2),
    dns_service:add("s2","IpAddr1",1000,vm3),
    timer:sleep(2000),
    dns_service:add("s2","IpAddr1",1000,vm3),
    [{"s1",_,_,_,_},
     {"s1",_,_,_,_},
     {"s1",_,_,_,_},
     {"s1",_,_,_,_}]=dns_service:expired(),
    dns_service:delete_expired(),
    [{"s2","IpAddr1",1000,vm3,_}]=dns_service:all(),
    dns_service:clear(),
    ok.



stop_dns_test()->
    Pod=misc_lib:get_node_by_id("pod_dns_1"),
    container:delete(Pod,"pod_dns_1",["dns_service"]),
    {ok,stopped}=pod:delete(node(),"pod_dns_1"),
    ok.


%**************************************************************
