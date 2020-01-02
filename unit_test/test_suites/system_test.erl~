%%% -------------------------------------------------------------------
%%% Author  : uabjle
%%% Description : dbase using dets 
%%%
%%% Created : 10 dec 2012
%%% -------------------------------------------------------------------
-module(unit_test). 
 
%% --------------------------------------------------------------------
%% Include files
%% --------------------------------------------------------------------
%-include_lib("eunit/include/eunit.hrl").

%% --------------------------------------------------------------------

%% External exports

-export([start/0]).


%% ====================================================================
%% External functions
%% ====================================================================
%% --------------------------------------------------------------------
%% Function:init 
%% Description:
%% Returns: non
%% --------------------------------------------------------------------
-define(TEST_OBJ_ERROR,[{adder_service,unit_test_adder_service},
			{glurk,test_glurk}]).
-define(TEST_OBJ,[ {lib_service,unit_test_lib_service},
		   {lib_service,unit_test_tcp_lib_service},
		   {adder_service,unit_test_adder_service}
		 ]).

-ifdef(error_test).
-define(TEST_CALL,[{test_case,Service,rpc:call(node(),UnitTestCode,test,[],5000)}
				   ||{Service,UnitTestCode}<-?TEST_OBJ_ERROR]).
-else.
-define(TEST_CALL,[{test_case,Service,rpc:call(node(),UnitTestCode,test,[],5000)}
				   ||{Service,UnitTestCode}<-?TEST_OBJ]).
-endif.

start()->
    %% set up test 
    os:cmd("erl -pa ebin -sname test_tcp_server -detached"),
    timer:sleep(200),
   % start_service('board_m1@asus',"pod_node_controller_m1",[{"lib_service",[]},{"node_controller_service",[]}]),
   % start_service('board_m2@asus',"pod_node_controller_m2",[{"lib_service",[]},{"node_controller_service",[]}]),
  %  start_service('board_w1@asus',"pod_node_controller_w1",[{"lib_service",[]},{"node_controller_service",[]}]),
  %  start_service('board_w2@asus',"pod_node_controller_w2",[{"lib_service",[]},{"node_controller_service",[]}]),
  %  start_service('board_w3@asus',"pod_node_controller_w3",[{"lib_service",[]},{"node_controller_service",[]}]),
    do_test(2).

do_test(0)->
  
  %  stop_service('board_m1@asus',"pod_node_controller_m1",ListOfServices),
  %  stop_service('board_m2@asus',"pod_node_controller_m2",ListOfServices),
  %  stop_service('board_w1@asus',"pod_node_controller_w1",ListOfServices),
  %  stop_service('board_w2@asus',"pod_node_controller_w2",ListOfServices),
  %  stop_service('board_w3@asus',"pod_node_controller_w3",ListOfServices),
    init:stop();
do_test(N)->
    io:format("N = ~p~n",[N]),
    R=?TEST_CALL,
    Error=[{test_case,Service,Result}||{test_case,Service,Result}<-R,Result/=ok],
    io:format("***************************    Unit test result     ***********************~n~n"),
    case Error of
	[]->
	    io:format("OK Unit test Passed ~p~n~n",[R]);
	Error->
	    io:format("ERROR Unit test failed = ~p~n~n",[Error])
    end,
   % init:stop(),
   % ok.
    os:cmd("erl -pa ebin -sname test_tcp_server -detached"),
    do_test(N-1).


%----------------------------------------------
start_service(Node,PodId,ListOfServices)->
    case pod:create(Node,PodId) of
	{error,Err}->
	    io:format(" ~p~n~n",[{error,Err}]);
	{ok,Pod}->
	    ok=container:create(Pod,PodId,ListOfServices)
    end.
    
stop_service(Node,PodId,ListOfServices)->
    {ok,Host}=rpc:call(Node,inet,gethostname,[]),
    PodIdServer=PodId++"@"++Host,
    Pod=list_to_atom(PodIdServer),
    container:delete(Pod,PodId,ListOfServices),
    {ok,stopped}=pod:delete(Node,PodId).
