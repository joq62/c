%%% -------------------------------------------------------------------
%%% Author  : uabjle
%%% Description : dbase using dets 
%%%
%%% Created : 10 dec 2012
%%% -------------------------------------------------------------------
-module(iaas_service_test). 
   
%% --------------------------------------------------------------------
%% Include files
%% --------------------------------------------------------------------

-include("test_src/common_macros.hrl").
%% --------------------------------------------------------------------

%% External exports
-export([test/0,
	 init_test/0,
	 init_start_computers_and_tcp_servers/0,
	 add_active_passive_status/0,
	 detect_lost_computer/0,
	 detect_restarted_computer/0,
	 missing_node_test/0,
	 cleanup/0
	]).
     
%-compile(export_all).



%% ====================================================================
%% External functions
%% ====================================================================
-define(TIMEOUT,1000*15).
test()->
    io:format("~p~n",[{?MODULE,?LINE}]),
    TestList=[init_test,
	      init_start_computers_and_tcp_servers,
	      add_active_passive_status,
	      detect_lost_computer,
	      detect_restarted_computer,
	      cleanup],
    test_support:execute(TestList,?MODULE,?TIMEOUT).	


%% --------------------------------------------------------------------
%% Function:init 
%% Description:
%% Returns: non
%% --------------------------------------------------------------------
init_test()->
    io:format("~p~n",[{?MODULE,?LINE}]),
    pod:delete(node(),"pod_dns_test"),
    {pong,_,lib_service}=lib_service:ping(),
    ok.
    

%**************************** tcp test   ****************************
init_start_computers_and_tcp_servers()->
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
    rpc:call(Computer_1,lib_service,start_tcp_server,["localhost",50001,sequence]),
    rpc:call(Computer_2,lib_service,start_tcp_server,["localhost",50002,sequence]),
    rpc:call(Computer_3,lib_service,start_tcp_server,["localhost",50003,sequence]),
    %% Check if running
    D=date(),
    {ok,Socket1}=tcp_client:connect("localhost",50001),
    tcp_client:cast(Socket1,{erlang,date,[]}),
    D=tcp_client:get_msg(Socket1,1000),
    tcp_client:disconnect(Socket1),
    {ok,Socket2}=tcp_client:connect("localhost",50002),
    tcp_client:cast(Socket2,{erlang,date,[]}),
    D=tcp_client:get_msg(Socket2,1000),
    tcp_client:disconnect(Socket2),
    {ok,Socket3}=tcp_client:connect("localhost",50003),
    tcp_client:cast(Socket3,{erlang,date,[]}),
    D=tcp_client:get_msg(Socket3,1000),
    tcp_client:disconnect(Socket3),
    ok.

add_active_passive_status()->

    {error,no_computers_allocated}=iaas_service:check_all_status(),

    iaas_service:add("localhost",50001,misc_lib:get_node_by_id("pod_computer_1"),active),
    [{ok,{"localhost",50001,pod_computer_1@asus},[]}
    ]=iaas_service:check_all_status(),
    
    %----
    [{"localhost",50001,pod_computer_1@asus}]=iaas_service:active(),
    []=iaas_service:passive(),
    active=iaas_service:status("localhost",50001,misc_lib:get_node_by_id("pod_computer_1")),
    {IpAddr,Port,Pod}={"glurk",50001,misc_lib:get_node_by_id("pod_computer_1")},
    {error,[undef,IpAddr,Port,Pod]
    }=iaas_service:status("glurk",50001,misc_lib:get_node_by_id("pod_computer_1")),

    D=date(),
    D=rpc:call(node(),tcp_client,call,[{"localhost",50001},{erlang,date,[]}],2000),
    iaas_service:add("localhost",50002,misc_lib:get_node_by_id("pod_computer_2"),active),
    iaas_service:add("localhost",50003,misc_lib:get_node_by_id("pod_computer_3"),active),
    L=iaas_service:check_all_status(),
    TestPattern=[{ok,{"localhost",50003,pod_computer_3@asus},[]},
		 {ok,{"localhost",50002,pod_computer_2@asus},[]},
		 {ok,{"localhost",50001,pod_computer_1@asus},[]}
		],
    TestL=[R||{R,_,_}<-L,R==ok],
    ok=case lists:flatlength(TestL) of
	   3->
	       ok;
	   _->
	       {"Result of call",L,"---------------","test pattern",TestPattern}
       end,

    TestL2=[R2||{_,{_,R2,_},_}<-L,
		(R2=:=50003)or(R2=:=50002)or(R2=:=50001)],
    ok=case lists:flatlength(TestL2) of
	   3->
	       ok;
	   _->
	       {"Result of call",L,"---------------","test pattern",TestPattern}
       end,	
    ok.
    
detect_lost_computer()->
    D=date(),
    D=rpc:call(node(),tcp_client,call,[{"localhost",50001},{erlang,date,[]}]),
    Computer_1=misc_lib:get_node_by_id("pod_computer_1"),
    container:delete(Computer_1,"pod_computer_1",["lib_service"]),
    {ok,stopped}=pod:delete(node(),"pod_computer_1"),
    TestPattern=[{ok,{"localhost",50003,pod_computer_3@asus},[]},
		 {ok,{"localhost",50002,pod_computer_2@asus},[]},
		 {error,{"localhost",50001,pod_computer_1@asus},[iaas,73,{error,[econnrefused]}]}],
    
    L=iaas_service:check_all_status(),
    TestL=[R||{R,_,_}<-L,R==ok],
    ok=case lists:flatlength(TestL) of
	   2->
	       ok;
	   _->
	       {"Result of call",L,"---------------","test pattern",TestPattern}
       end,
    
    %-----------
    [{"localhost",50001,pod_computer_1@asus}]=iaas_service:passive(),

    TestPattern2=[{"localhost",50002,pod_computer_2@asus},
		  {"localhost",50003,pod_computer_3@asus}],
    L2=iaas_service:active(),    
    TestL2=[R2||{_,R2,_}<-L2,
		(R2=:=50003)or(R2=:=50002)],
    ok=case lists:flatlength(TestL2) of
	   2->
	       ok;
	   _->
	       {"Result of call",L2,"---------------","test pattern",TestPattern2}
       end,
    ok.
    

detect_restarted_computer()->
    {ok,Computer_1}=pod:create(node(),"pod_computer_1"),
    ok=container:create(Computer_1,"pod_computer_1",
			[{{service,"lib_service"},
			  {dir,"/home/pi/erlang/c/source"}}
			]),    
    rpc:call(Computer_1,lib_service,start_tcp_server,["localhost",50001,sequence]),
    D=date(),
    D=rpc:call(node(),tcp_client,call,[{"localhost",50001},{erlang,date,[]}]),
    
    TestPattern=[{ok,{"localhost",50003,pod_computer_3@asus},[]},
		 {ok,{"localhost",50002,pod_computer_2@asus},[]},
		 {ok,{"localhost",50001,pod_computer_1@asus},[]}],

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
		  {ok,{"localhost",50003,pod_computer_3@asus},[]},
		  {ok,{"localhost",50002,pod_computer_2@asus},[]},
		  {ok,{"localhost",50001,pod_computer_1@asus},[]}],

    

    L1=iaas_service:check_all_status(),
    TestL1=[R||{R,_,_}<-L1,R==ok],
    ok=case lists:flatlength(TestL1) of
	   3->
	       ok;
	   _->
	       {"Result of call",L1,"---------------","test pattern",TestPattern1}
       end,

    iaas_service:delete("localhost",5522,node()),
    TestPattern2=[{ok,{"localhost",50003,pod_computer_3@asus},[]},
		  {ok,{"localhost",50002,pod_computer_2@asus},[]},
		  {ok,{"localhost",50001,pod_computer_1@asus},[]}],
    L2=iaas_service:check_all_status(),
    TestL2=[R||{R,_,_}<-L2,R==ok],
    ok=case lists:flatlength(TestL2) of
	   3->
	       ok;
	   _->
	       {"Result of call",L2,"---------------","test pattern",TestPattern2}
       end,
    ok.
    


    
cleanup()->
    Computer_1=misc_lib:get_node_by_id("pod_computer_1"),
    container:delete(Computer_1,"pod_computer_1",["lib_service"]),
    {ok,stopped}=pod:delete(node(),"pod_computer_1"),
    Computer_2=misc_lib:get_node_by_id("pod_computer_2"),
    container:delete(Computer_2,"pod_computer_2",["lib_service"]),
    {ok,stopped}=pod:delete(node(),"pod_computer_2"),
    Computer_3=misc_lib:get_node_by_id("pod_computer_3"),
    container:delete(Computer_3,"pod_computer_3",["lib_service"]),
    {ok,stopped}=pod:delete(node(),"pod_computer_3"),

    PodDns=misc_lib:get_node_by_id("pod_dns_test"),
    container:delete(PodDns,"pod_dns_test",["dns_service"]),
    container:delete(PodDns,"pod_dns_test",["lib_service"]),
    {ok,stopped}=pod:delete(node(),"pod_dns_test"),

    ok.


%**************************************************************
