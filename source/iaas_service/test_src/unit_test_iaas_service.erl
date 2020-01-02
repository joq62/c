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

%% External exports
-export([test/0,
	init_test/0,init_tcp_test/0,
	start_iaas_test/0,node_down_test/0,node_up_again_test/0,
	missing_node_test/0,
	end_tcp_test/0]).
     
%-compile(export_all).

-define(TIMEOUT,1000*15).

%% ====================================================================
%% External functions
%% ====================================================================
test()->
    TestList=[init_test,init_tcp_test,
	      start_iaas_test,node_down_test,node_up_again_test,
	      missing_node_test,
	      end_tcp_test],
    test_support:execute(TestList,?MODULE,?TIMEOUT).	


%% --------------------------------------------------------------------
%% Function:init 
%% Description:
%% Returns: non
%% --------------------------------------------------------------------
init_test()->
    {pong,_,iaas_service}=iaas_service:ping(),
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
    rpc:call(Computer_1,lib_service,start_tcp_server,["localhost",42001,sequence]),
    rpc:call(Computer_2,lib_service,start_tcp_server,["localhost",42002,sequence]),
    rpc:call(Computer_3,lib_service,start_tcp_server,["localhost",42003,sequence]),
    %% Check if running
    D=date(),
    {ok,P1}=tcp_client:connect("localhost",42001),
    tcp_client:cast(P1,{erlang,date,[]}),
    D=tcp_client:get_msg(P1,1000),
    tcp_client:disconnect(P1),
    {ok,P2}=tcp_client:connect("localhost",42002),
    tcp_client:cast(P2,{erlang,date,[]}),
    D=tcp_client:get_msg(P2,1000),
    tcp_client:disconnect(P2),
    {ok,P3}=tcp_client:connect("localhost",42003),
    tcp_client:cast(P3,{erlang,date,[]}),
    D=tcp_client:get_msg(P3,1000),
    tcp_client:disconnect(P3),
    ok.

start_iaas_test()->

    {error,no_computers_allocated}=iaas_service:check_all_status(),

    iaas_service:add("localhost",42001,misc_lib:get_node_by_id("pod_computer_1"),active),
    [{ok,{"localhost",42001,pod_computer_1@asus},[]}
    ]=iaas_service:check_all_status(),
    
    %----
    [{"localhost",42001,pod_computer_1@asus}]=iaas_service:active(),
    []=iaas_service:passive(),
    active=iaas_service:status("localhost",42001,misc_lib:get_node_by_id("pod_computer_1")),
    {IpAddr,Port,Pod}={"glurk",42001,misc_lib:get_node_by_id("pod_computer_1")},
    {error,[undef,IpAddr,Port,Pod]
    }=iaas_service:status("glurk",42001,misc_lib:get_node_by_id("pod_computer_1")),

    D=date(),
    D=rpc:call(node(),tcp_client,call,[{"localhost",42001},{erlang,date,[]}],2000),
    iaas_service:add("localhost",42002,misc_lib:get_node_by_id("pod_computer_2"),active),
    iaas_service:add("localhost",42003,misc_lib:get_node_by_id("pod_computer_3"),active),
    L=iaas_service:check_all_status(),
    TestPattern=[{ok,{"localhost",42003,pod_computer_3@asus},[]},
		 {ok,{"localhost",42002,pod_computer_2@asus},[]},
		 {ok,{"localhost",42001,pod_computer_1@asus},[]}
		],
    TestL=[R||{R,_,_}<-L,R==ok],
    ok=case lists:flatlength(TestL) of
	   3->
	       ok;
	   _->
	       {"Result of call",L,"---------------","test pattern",TestPattern}
       end,

    TestL2=[R2||{_,{_,R2,_},_}<-L,
		(R2=:=42003)or(R2=:=42002)or(R2=:=42001)],
    ok=case lists:flatlength(TestL2) of
	   3->
	       ok;
	   _->
	       {"Result of call",L,"---------------","test pattern",TestPattern}
       end,	
    ok.
    
node_down_test()->
    D=date(),
    D=rpc:call(node(),tcp_client,call,[{"localhost",42001},{erlang,date,[]}]),
    Computer_1=misc_lib:get_node_by_id("pod_computer_1"),
    container:delete(Computer_1,"pod_computer_1",["lib_service"]),
    {ok,stopped}=pod:delete(node(),"pod_computer_1"),
    TestPattern=[{ok,{"localhost",42003,pod_computer_3@asus},[]},
		 {ok,{"localhost",42002,pod_computer_2@asus},[]},
		 {error,{"localhost",42001,pod_computer_1@asus},[iaas,73,{error,[econnrefused]}]}],
    
    L=iaas_service:check_all_status(),
    TestL=[R||{R,_,_}<-L,R==ok],
    ok=case lists:flatlength(TestL) of
	   2->
	       ok;
	   _->
	       {"Result of call",L,"---------------","test pattern",TestPattern}
       end,
    
    %-----------
    [{"localhost",42001,pod_computer_1@asus}]=iaas_service:passive(),

    TestPattern2=[{"localhost",42002,pod_computer_2@asus},
		  {"localhost",42003,pod_computer_3@asus}],
    L2=iaas_service:active(),    
    TestL2=[R2||{_,R2,_}<-L2,
		(R2=:=42003)or(R2=:=42002)],
    ok=case lists:flatlength(TestL2) of
	   2->
	       ok;
	   _->
	       {"Result of call",L2,"---------------","test pattern",TestPattern2}
       end,
    ok.
    

node_up_again_test()->
    {ok,Computer_1}=pod:create(node(),"pod_computer_1"),
    ok=container:create(Computer_1,"pod_computer_1",
			[{{service,"lib_service"},
			  {dir,"/home/pi/erlang/c/source"}}
			]),    
    rpc:call(Computer_1,lib_service,start_tcp_server,["localhost",42001,sequence]),
    D=date(),
    D=rpc:call(node(),tcp_client,call,[{"localhost",42001},{erlang,date,[]}]),
    
    TestPattern=[{ok,{"localhost",42003,pod_computer_3@asus},[]},
		 {ok,{"localhost",42002,pod_computer_2@asus},[]},
		 {ok,{"localhost",42001,pod_computer_1@asus},[]}],

    L=iaas_service:check_all_status(),
    TestL=[R||{R,_,_}<-L,R==ok],
    ok=case lists:flatlength(TestL) of
	  3->
	       ok;
	   _->
	       {"Result of call",L,"---------------","test pattern",TestPattern}
       end,
    
    ok.
missing_node_test()->
    iaas_service:add("localhost",5522,node(),active),
    TestPattern1=[{error,{"localhost",5522,pod_test_1@asus},[iaas,xx,{error,[econnrefused]}]},
		  {ok,{"localhost",42003,pod_computer_3@asus},[]},
		  {ok,{"localhost",42002,pod_computer_2@asus},[]},
		  {ok,{"localhost",42001,pod_computer_1@asus},[]}],

    

    L1=iaas_service:check_all_status(),
    TestL1=[R||{R,_,_}<-L1,R==ok],
    ok=case lists:flatlength(TestL1) of
	   3->
	       ok;
	   _->
	       {"Result of call",L1,"---------------","test pattern",TestPattern1}
       end,

    iaas_service:delete("localhost",5522,node()),
    TestPattern2=[{ok,{"localhost",42003,pod_computer_3@asus},[]},
		  {ok,{"localhost",42002,pod_computer_2@asus},[]},
		  {ok,{"localhost",42001,pod_computer_1@asus},[]}],
    L2=iaas_service:check_all_status(),
    TestL2=[R||{R,_,_}<-L2,R==ok],
    ok=case lists:flatlength(TestL2) of
	   3->
	       ok;
	   _->
	       {"Result of call",L2,"---------------","test pattern",TestPattern2}
       end,
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
