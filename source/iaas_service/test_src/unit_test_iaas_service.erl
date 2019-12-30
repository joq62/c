%%% -------------------------------------------------------------------
%%% Author  : uabjle
%%% Description : dbase using dets 
%%%
%%% Created : 10 dec 2012
%%% -------------------------------------------------------------------
-module(unit_test_iaas_service). 
  
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
    TestList=[init_test,init_tcp_test,
	      start_iaas_test,node_down_test,node_up_again_test,
	      missing_node_test,
	      end_tcp_test],
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
    

%**************************** tcp test   ****************************
init_tcp_test()->
    {ok,Computer_1}=pod:create(node(),"pod_computer_1"),
    ok=container:create(Computer_1,"pod_computer_1",
			[{{service,"lib_service"},
			  {dir,"/home/pi/erlang/c/source"}}
			]),    
    {ok,Computer_2}=pod:create(node(),"pod_computer_2"),
    ok=container:create(Computer_2,"pod_computer_2",
			[{{service,"lib_service"},
			  {dir,"/home/pi/erlang/c/source"}}
			]),    

    {ok,Computer_3}=pod:create(node(),"pod_computer_3"),
    ok=container:create(Computer_3,"pod_computer_3",
			[{{service,"lib_service"},
			  {dir,"/home/pi/erlang/c/source"}}
			]),    
    rpc:call(Computer_1,tcp_server,start_seq_server,[42001]),
    rpc:call(Computer_2,tcp_server,start_seq_server,[42002]),
    rpc:call(Computer_3,tcp_server,start_seq_server,[42003]),
    %% Check if running
    D=date(),
    P1=tcp_client:connect("localhost",42001),
    tcp_client:session_call(P1,Computer_1,{erlang,date,[]}),
    D=tcp_client:get_msg(P1,1000),
    tcp_client:disconnect(P1),
    P2=tcp_client:connect("localhost",42002),
    tcp_client:session_call(P2,{erlang,date,[]}),
    D=tcp_client:get_msg(P2,1000),
    tcp_client:disconnect(P2),
    P3=tcp_client:connect("localhost",42003),
    tcp_client:session_call(P3,{erlang,date,[]}),
    D=tcp_client:get_msg(P3,1000),
    tcp_client:disconnect(P3),

   % D=rpc:call(node(),tcp_client,call,[{"localhost",42001},Computer_1,{erlang,date,[]}]),
   % D=rpc:call(node(),tcp_client,call,[{"localhost",42002},Computer_2,{erlang,date,[]}]),
   % D=rpc:call(node(),tcp_client,call,[{"localhost",42003},Computer_3,{erlang,date,[]}]),

    ok.

start_iaas_test()->
%    iaas:init(),
    {error,no_computers_allocated}=iaas_service:check_all_status(),
    iaas_service:add("localhost",42001,misc_lib:get_node_by_id("pod_computer_1"),active),
    [{ok,["localhost",42001,pod_computer_1@asus]}
    ]=iaas_service:check_all_status(),
    
    D=date(),
    D=rpc:call(node(),tcp_client,call,[{"localhost",42001},misc_lib:get_node_by_id("pod_computer_1"),{erlang,date,[]}],2000),
    iaas_service:add("localhost",42002,misc_lib:get_node_by_id("pod_computer_2"),active),
    iaas_service:add("localhost",42003,misc_lib:get_node_by_id("pod_computer_3"),active),
    [{ok,["localhost",42003,pod_computer_3@asus]},
     {ok,["localhost",42002,pod_computer_2@asus]},
     {ok,["localhost",42001,pod_computer_1@asus]}]=iaas_service:check_all_status(),

    [{ok,["localhost",42003,pod_computer_3@asus]},
     {ok,["localhost",42002,pod_computer_2@asus]},
     {ok,["localhost",42001,pod_computer_1@asus]}]=iaas_service:check_all_status(),

    ok.
    
node_down_test()->
    D=date(),
    D=rpc:call(node(),tcp_client,call,[{"localhost",42001},misc_lib:get_node_by_id("pod_computer_1"),{erlang,date,[]}]),
    Computer_1=misc_lib:get_node_by_id("pod_computer_1"),
    container:delete(Computer_1,"pod_computer_1",["lib_service"]),
    {ok,stopped}=pod:delete(node(),"pod_computer_1"),
    [{ok,["localhost",42003,pod_computer_3@asus]},
     {ok,["localhost",42002,pod_computer_2@asus]},
     {error,[{error,[econnrefused]},"localhost",42001,pod_computer_1@asus,iaas,_Line]}
    ]=iaas_service:check_all_status(),
       
    ok.

node_up_again_test()->
    {ok,Computer_1}=pod:create(node(),"pod_computer_1"),
    ok=container:create(Computer_1,"pod_computer_1",
			[{{service,"lib_service"},
			  {dir,"/home/pi/erlang/c/source"}}
			]),    
    rpc:call(Computer_1,tcp_server,start_seq_server,[42001]),
    D=date(),
    D=rpc:call(node(),tcp_client,call,[{"localhost",42001},misc_lib:get_node_by_id("pod_computer_1"),{erlang,date,[]}]),
    
    [{ok,["localhost",42003,pod_computer_3@asus]},
     {ok,["localhost",42002,pod_computer_2@asus]},
     {ok,["localhost",42001,pod_computer_1@asus]}]=iaas_service:check_all_status(),
    
    ok.
missing_node_test()->
    iaas_service:add("localhost",5522,node(),active),
    [{error,[{error,[econnrefused]},"localhost",5522,pod_test_1@asus,iaas,_Line]},
     {ok,["localhost",42003,pod_computer_3@asus]},
     {ok,["localhost",42002,pod_computer_2@asus]},
     {ok,["localhost",42001,pod_computer_1@asus]}
    ]=iaas_service:check_all_status(),

    iaas_service:delete("localhost",5522,node()),
    [{ok,["localhost",42003,pod_computer_3@asus]},
     {ok,["localhost",42002,pod_computer_2@asus]},
     {ok,["localhost",42001,pod_computer_1@asus]}]=iaas_service:check_all_status(),
    ok.
    


    
end_tcp_test()->
    Computer_1=misc_lib:get_node_by_id("pod_computer_1"),
    container:delete(Computer_1,"pod_computer_1",["lib_service"]),
    {ok,stopped}=pod:delete(node(),"pod_computer_1"),
    Computer_2=misc_lib:get_node_by_id("pod_computer_2"),
    container:delete(Computer_2,"pod_computer_2",["lib_service"]),
    {ok,stopped}=pod:delete(node(),"pod_computer_2"),
    Computer_3=misc_lib:get_node_by_id("pod_computer_3"),
    container:delete(Computer_3,"pod_computer_3",["lib_service"]),
    {ok,stopped}=pod:delete(node(),"pod_computer_3"),

    ok.


%**************************************************************
