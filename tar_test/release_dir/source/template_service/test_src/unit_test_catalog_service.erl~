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
-include_lib("eunit/include/eunit.hrl").

%% --------------------------------------------------------------------

%% External exports

-export([]).


%% ====================================================================
%% External functions
%% ====================================================================
%% --------------------------------------------------------------------
%% Function:init 
%% Description:
%% Returns: non
%% --------------------------------------------------------------------
init_test()->
    ok=application:start(log_service),
    ok.

t1_test()->
    log_service:store({2019,10,20},{22,00,10},node_1,module_1,1,error,["test 1",glurk]),
    log_service:store({2019,10,10},{01,32,55},node_2,module_2,2,warning,["test 2",glurk]),
    log_service:store({2019,10,20},{22,00,00},node_1,module_3,3,info,["test 3",glurk]),      
    log_service:store({2019,10,21},{13,10,00},node_4,module_4,4,warning,["test 4",glurk]),
    ok.

read_file_test()->
    [{{2019,10,21},{13,10,0},node_4,module_4,4,warning,["test 4",glurk]},
     {{2019,10,20},{22,0,0},node_1,module_3,3,info,["test 3",glurk]},
     {{2019,10,10},{1,32,55},node_2,module_2,2,warning,["test 2",glurk]},
     {{2019,10,20},{22,0,10},node_1,module_1,1,error,["test 1",glurk]}]=log_service:all(),
    ok.

sevrity_test()->
    [{{2019,10,21},{13,10,0},node_4,module_4,4,warning,["test 4",glurk]},
     {{2019,10,10},{1,32,55},node_2,module_2,2,warning,["test 2",glurk]}]=log_service:severity(warning),
    [{{2019,10,20},{22,0,10},node_1,module_1,1,error,["test 1",glurk]}]=log_service:severity(error),
    []=log_service:severity(glurk),
    ok.

latest_event_test()->
    [{{2019,10,21},{13,10,0},node_4,module_4,4,warning,["test 4",glurk]}]=log_service:latest_event(),
    
    [{{2019,10,21},{13,10,0},node_4,module_4,4,warning,["test 4",glurk]},
     {{2019,10,20},{22,0,0},node_1,module_3,3,info,["test 3",glurk]},
     {{2019,10,10},{1,32,55},node_2,module_2,2,warning,["test 2",glurk]}]=log_service:latest_events(3),
    ok.
node_module_test()->
    [{{2019,10,10},{1,32,55},node_2,module_2,2,warning,["test 2",glurk]}]=log_service:node(node_2),
    [{{2019,10,20},{22,0,10},node_1,module_1,1,error,["test 1",glurk]}]=log_service:module(module_1),
    ok.

date_test()->
    [{{2019,10,20},{22,0,10},node_1,module_1,1,error,["test 1",glurk]},
     {{2019,10,10},{1,32,55},node_2,module_2,2,warning,["test 2",glurk]},
     {{2019,10,20},{22,0,0},node_1,module_3,3,info,["test 3",glurk]},
     {{2019,10,21},{13,10,0},node_4,module_4,4,warning,["test 4",glurk]}]=log_service:year(2019),

    [{{2019,10,20},{22,0,10},node_1,module_1,1,error,["test 1",glurk]},
     {{2019,10,10},{1,32,55},node_2,module_2,2,warning,["test 2",glurk]},
     {{2019,10,20},{22,0,0},node_1,module_3,3,info,["test 3",glurk]},
     {{2019,10,21},{13,10,0},node_4,module_4,4,warning,["test 4",glurk]}]=log_service:month(2019,10),
    
    [{{2019,10,20},{22,0,10},node_1,module_1,1,error,["test 1",glurk]},
     {{2019,10,20},{22,0,0},node_1,module_3,3,info,["test 3",glurk]}]=log_service:day(2019,10,20),
    [{{2019,10,10},{1,32,55},node_2,module_2,2,warning,["test 2",glurk]}]=log_service:day(2019,10,10),
    ok.

stop_test()->
    ok=application:stop(log_service),
    ok=application:unload(log_service),
    file:delete("latest.log"),
    init:stop(),
    ok.
