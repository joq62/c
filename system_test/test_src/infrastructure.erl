%%% -------------------------------------------------------------------
%%% Author  : uabjle
%%% Description : dbase using dets 
%%%
%%% Created : 10 dec 2012
%%% -------------------------------------------------------------------
-module(infrastructure). 
  
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
% ComputerList=[{"master_computer",'master_computer@asus',"localhost",42000},
%  {"w1_computer",'w1_computer@asus',"localhost",42001},
%  {"w2_computer",'w2_computer@asus',"localhost",42002}]
% LibService=[{{service,"libservice_service"},{dir,"/home/pi/erlang/c/source"}}]
% AppList={{service,"iaas_service"},{dir,"/home/pi/erlang/c/source"},{computer,"master_computer",'master_computer@asus'}}

start(ComputerList,LibService)->
    PodList=[{pod:create(node(),ComputerId),ComputerId}||{ComputerId,Computer,_IpAddr,_Port}<-ComputerList],
    [pong,pong,pong]=[rpc:call(node(),net_adm,ping,[Computer])||{{ok,Computer},_ComputerId}<-PodList],
    % Pods ok 
    % Start lib_service on all nodes
    [container:create(Computer,ComputerId,LibService)||{{ok,Computer},ComputerId}<-PodList],
    
    % Allocate a tcp Server per Computer
    
    [rpc:call(Computer,tcp_server,start_par_server,[Port])||{_ComputerId,Computer,_IpAddr,Port}<-ComputerList],
    [{pong,_,_},
     {pong,_,_},
     {pong,_,_}]=[rpc:call(node(),tcp_client,call,[{IpAddr,Port},{lib_service,ping,[]}])||{_ComputerId,_Computer,IpAddr,Port}<-ComputerList],
    % computers started and lib_service installed
    io:format(" ~n"),
    io:format("~p",[time()]),
    io:format("  OK :~p~n",[{?MODULE,start}]),
    io:format(" ~n"),
    ok.

stop(ComputerList)->	
    [container:delete(Computer,ComputerId,["lib_service"])||{ComputerId,Computer,_,_}<-ComputerList],
    [pod:delete(node(),ComputerId)||{ComputerId,_Computer,_,_}<-ComputerList],
    [pang,pang,pang]=[rpc:call(node(),net_adm,ping,[Computer])||{_ComputerId,Computer,_,_}<-ComputerList],
    io:format(" ~n"),
    io:format("~p",[time()]),
    io:format("  OK :~p~n",[{?MODULE,stop}]),
    io:format(" ~n"), 
   ok.
    

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
