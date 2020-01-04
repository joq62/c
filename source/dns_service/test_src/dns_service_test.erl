%%% -------------------------------------------------------------------
%%% Author  : uabjle
%%% Description : dbase using dets 
%%%
%%% Created : 10 dec 2012
%%% -------------------------------------------------------------------
-module(dns_service_test).  
  
%% --------------------------------------------------------------------
%% Include files
%% --------------------------------------------------------------------
-include("test_src/common_macros.hrl").
%% --------------------------------------------------------------------

%% External exports
-export([test/0,
	 init_test/0,start_dns_test/0,
	 dns_add_delete_all_test/0,
	 dns_expired_test/0,
	 stop_dns_test/0
	]).
	 
%-compile(export_all).

-define(TIMEOUT,1000*15).

%% ====================================================================
%% External functions
%% ====================================================================
test()->
    {pong,_,lib_service}=lib_service:ping(),
    TestList=[init_test,
	      start_dns_test,
	      dns_add_delete_all_test,
	      dns_expired_test,
	      stop_dns_test 
	     ],
    test_support:execute(TestList,?MODULE,?TIMEOUT).


%% --------------------------------------------------------------------
%% Function:init 
%% Description:
%% Returns: non
%% --------------------------------------------------------------------
init_test()->
    tcp_client:call(?DNS_ADDRESS,{init,stop,[]}),
    pod:delete(node(),"pod_dns_1"),
    pod:delete(node(),"pod_master"),
 
    {pong,_,lib_service}=lib_service:ping(),
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
    timer:sleep(100),
    ok=rpc:call(Pod,lib_service,start_tcp_server,[?DNS_ADDRESS,parallell],2000),
    {pong,_,dns_service}=tcp_client:call(?DNS_ADDRESS,{dns_service,ping,[]}),
 %  glurk=rpc:call(Pod,dns_lib,get_expired_time,[]),
   ok.

dns_add_delete_all_test()->
    % add,delete, all
    true=tcp_client:call(?DNS_ADDRESS,{dns_service,add,["s1","IpAddr1",1000,vm1]}),
    timer:sleep(50),
    [{"s1","IpAddr1",1000,vm1,_}]=tcp_client:call(?DNS_ADDRESS,{dns_service,all,[]}),
    [["IpAddr1",1000,vm1]]=tcp_client:call(?DNS_ADDRESS,{dns_service,get,["s1"]}),
    
    % duplicate test
    true=tcp_client:call(?DNS_ADDRESS,{dns_service,add,["s1","IpAddr1",1000,vm1]}),
    timer:sleep(50),
    [{"s1","IpAddr1",1000,vm1,_}]=tcp_client:call(?DNS_ADDRESS,{dns_service,all,[]}),
    [["IpAddr1",1000,vm1]]=tcp_client:call(?DNS_ADDRESS,{dns_service,get,["s1"]}),

    % delete test
    true=tcp_client:call(?DNS_ADDRESS,{dns_service,delete,["s1","IpAddr1",1000,vm1]}),
    timer:sleep(50),
    []=tcp_client:call(?DNS_ADDRESS,{dns_service,all,[]}),
    []=tcp_client:call(?DNS_ADDRESS,{dns_service,get,["s1"]}),
    tcp_client:call(?DNS_ADDRESS,{dns_service,clear,[]}),
    ok.


dns_expired_test()->
    % expired test
    true=tcp_client:call(?DNS_ADDRESS,{dns_service,add,["s1","IpAddr1",1000,vm1]}),

    timer:sleep(50),
    tcp_client:call(?DNS_ADDRESS,{dns_service,get,["s1"]}),
    
    true=tcp_client:call(?DNS_ADDRESS,{dns_service,add,["s1","IpAddr1",1001,vm1]}),
    true=tcp_client:call(?DNS_ADDRESS,{dns_service,add,["s1","IpAddr2",1001,vm1]}),
    true=tcp_client:call(?DNS_ADDRESS,{dns_service,add,["s1","IpAddr1",1000,vm2]}),
    true=tcp_client:call(?DNS_ADDRESS,{dns_service,add,["s2","IpAddr1",1000,vm3]}),
    % Make  S1 expired S1 
    timer:sleep(2000),
    true=tcp_client:call(?DNS_ADDRESS,{dns_service,add,["s2","IpAddr1",1000,vm3]}),
    [{"s1",_,_,_,_},
     {"s1",_,_,_,_},
     {"s1",_,_,_,_},
    {"s1",_,_,_,_}]=tcp_client:call(?DNS_ADDRESS,{dns_service,expired,[]}),
     tcp_client:call(?DNS_ADDRESS,{dns_service,delete_expired,[]}),
   
     [{"s2","IpAddr1",1000,vm3,_}]=tcp_client:call(?DNS_ADDRESS,{dns_service,all,[]}),
     tcp_client:call(?DNS_ADDRESS,{dns_service,clear,[]}),
     ok.



stop_dns_test()->
    Pod=misc_lib:get_node_by_id("pod_dns_1"),
    {ok,stopped}=rpc:call(Pod,lib_service,stop_tcp_server,[?DNS_ADDRESS],2000),
    Pod=misc_lib:get_node_by_id("pod_dns_1"),
    container:delete(Pod,"pod_dns_1",["dns_service"]),
    {ok,stopped}=pod:delete(node(),"pod_dns_1"),
    ok.


%**************************************************************
