%%% -------------------------------------------------------------------
%%% Author  : uabjle
%%% Description : dbase using dets 
%%%
%%% Created : 10 dec 2012
%%% -------------------------------------------------------------------
-module(unit_test_log_service). 
 
%% --------------------------------------------------------------------
%% Include files
%% --------------------------------------------------------------------
%% --------------------------------------------------------------------
-define(TIMEOUT,1000*15).

%% External exports

-export([test/0,
	 init_test/0,
	 start_log_test/0,
	 read_file_test/0,sevrity_test/0,
	 latest_event_test/0,node_module_test/0,
	 date_test/0,
	 stop_log_test/0
	]).

%-compile(export_all).



%% ====================================================================
%% External functions
%% ====================================================================
%% --------------------------------------------------------------------
%% Function:init 
%% Description:
%% Returns: non
%% --------------------------------------------------------------------
test()->
    TestList=[init_test,
	      start_log_test,
	      read_file_test,sevrity_test,
	      latest_event_test,node_module_test,date_test,
	      stop_log_test
	     ],
    test_support:execute(TestList,?MODULE,?TIMEOUT).

%% --------------------------------------------------------------------
%% Function:init 
%% Description:
%% Returns: non
%% --------------------------------------------------------------------
init_test()->
    {pong,_,log_service}=log_service:ping(),
    {ok,Pod}=pod:create(node(),"pod_1"),
   % ok=container:create(Pod,"pod_1",
%			[{{service,"lib_service"},
%			  {dir,"/home/pi/erlang/c/source"}}
%			]),
    ok=container:create(Pod,"pod_1",
			[{{service,"log_service"},
			  {dir,"/home/pi/erlang/c/source"}}
			]),
   os:cmd("rm latest.log"),
   ok.      

stop_log_test()->
    os:cmd("rm latest.log"),
    Pod=misc_lib:get_node_by_id("pod_1"),
    container:delete(Pod,"pod_1",["dns_service"]),
    {ok,stopped}=pod:delete(node(),"pod_1"),
    ok.


%**************************************************************
%------------------  -------
%create_container(Pod,PodId,[{{service,ServiceId},{Type,Source}}

start_log_test()->
    log_service:store({2019,10,20},{22,00,10},ipaddr1,port1,pod1,module_1,1,error,["test 1",glurk]),
    log_service:store({2019,10,10},{01,32,55},ipaddr2,port2,pod2,module_2,2,warning,["test 2",glurk]),
    log_service:store({2019,10,20},{22,00,00},ipaddr1,port1,pod1,module_3,3,info,["test 3",glurk]),      
    log_service:store({2019,10,21},{13,10,00},ipaddr4,port4,pod4,module_4,4,warning,["test 4",glurk]),
    ok.  

read_file_test()->
    [{{2019,10,21},{13,10,0},ipaddr4,port4,pod4,module_4,4,warning,["test 4",glurk]},
     {{2019,10,20},{22,0,0},ipaddr1,port1,pod1,module_3,3,info,["test 3",glurk]},
     {{2019,10,10},{1,32,55},ipaddr2,port2,pod2,module_2,2,warning,["test 2",glurk]},
     {{2019,10,20},{22,0,10},ipaddr1,port1,pod1,module_1,1,error,["test 1",glurk]}]=log_service:all(),
    ok.

sevrity_test()->
    [{{2019,10,20},{22,0,10},ipaddr1,port1,pod1,module_1,1,error,["test 1",glurk]}]=log_service:severity(error),
    []=log_service:severity(glurk),
    ok.

latest_event_test()->
  [{{2019,10,21},{13,10,0},ipaddr4,port4,pod4,module_4,4,warning,["test 4",glurk]}
  ]=log_service:latest_event(),
    
    [{{2019,10,21},{13,10,0},ipaddr4,port4,pod4,module_4,4,warning,["test 4",glurk]},
     {{2019,10,20},{22,0,0},ipaddr1,port1,pod1,module_3,3,info,["test 3",glurk]},
     {{2019,10,10},{1,32,55},ipaddr2,port2,pod2,module_2,2,warning,["test 2",glurk]}
    ]=log_service:latest_events(3),
    ok.
node_module_test()->
   [{{2019,10,10},{1,32,55},ipaddr2,port2,pod2,module_2,2,warning,["test 2",glurk]}
   ]=log_service:node(ipaddr2,port2,pod2),
    [{{2019,10,20},{22,0,10},ipaddr1,port1,pod1,module_1,1,error,["test 1",glurk]}
    ]=log_service:module(module_1),
    ok.

date_test()->
    [{{2019,10,20},{22,0,10},ipaddr1,port1,pod1,module_1,1,error,["test 1",glurk]},
     {{2019,10,10},{1,32,55},ipaddr2,port2,pod2,module_2,2,warning,["test 2",glurk]},
     {{2019,10,20},{22,0,0},ipaddr1,port1,pod1,module_3,3,info,["test 3",glurk]},
     {{2019,10,21},{13,10,0},ipaddr4,port4,pod4,module_4,4,warning,["test 4",glurk]}
    ]=log_service:year(2019),

   [{{2019,10,20}, {22,0,10},ipaddr1,port1,pod1,module_1,1,error, ["test 1",glurk]},
    {{2019,10,10},{1,32,55},ipaddr2,port2,pod2,module_2,2,warning, ["test 2",glurk]},
    {{2019,10,20},{22,0,0},ipaddr1,port1,pod1,module_3,3,info,["test 3",glurk]},
    {{2019,10,21},{13,10,0},ipaddr4,port4,pod4,module_4,4,warning,["test 4",glurk]}
   ]=log_service:month(2019,10),
    
    [{{2019,10,20},{22,0,10},ipaddr1,port1,pod1,module_1,1,error,["test 1",glurk]},
     {{2019,10,20},{22,0,0},ipaddr1,port1,pod1,module_3,3,info,["test 3",glurk]}
    ]=log_service:day(2019,10,20),
    [{{2019,10,10},{1,32,55},ipaddr2,port2,pod2,module_2,2,warning,["test 2",glurk]}]=log_service:day(2019,10,10),
    ok.
