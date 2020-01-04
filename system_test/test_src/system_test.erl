%%% -------------------------------------------------------------------
%%% Author  : uabjle
%%% Description : dbase using dets 
%%%
%%% Created : 10 dec 2012
%%% -------------------------------------------------------------------
-module(system_test). 
 
%% --------------------------------------------------------------------
%% Include files
%% --------------------------------------------------------------------


%% --------------------------------------------------------------------

%% External exports
-export([start/0,start/1,
	get/1,delete/1,all/0,test_ets/0
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

-define(TEST_SPEC,"system_test.spec").
-define(ETS,system_test_ets).
start()->
    start(?TEST_SPEC).
start(TestSpec)->

    io:format("  ~n"),
    io:format(" ***************** ~p",[time()]),
    io:format(" Test started :~p~n",[{?MODULE,start}]),
    io:format(" ~n"),

    % Need to load start lib_service
    application:start(lib_service),
    ets_init(TestSpec),
    [{test_files,TestFiles}]=system_test:get(test_files),
    TestResult=[do_test(M,F)||{M,F}<-TestFiles],
    io:format("  ~n"),
    io:format(" ***************** ~p",[time()]),
    io:format("Test result ********* ~n  ~p~n",[TestResult]),
    
    init:stop(),
    ok.

do_test(M,F)->
    R=rpc:call(node(),M,F,[]),
    Result=case R of 
	       ok->
		   {ok,M,F};
	       Err ->
		   io:format("Sub test  ~p~n",[{error,M,F,Err}]),
		   {error,M,F,Err}
	   end,
    Result.

%% --------------------------------------------------------------------
%% Function:init 
%% Description:
%% Returns: non
%% --------------------------------------------------------------------
ets_init(TestSpec)->
    ets:new(?ETS, [bag, named_table]),
    Result=case file:consult(TestSpec) of
	       {ok,I}->
		   add(lists:keyfind(computers,1,I)),
		   add(lists:keyfind(lib_service,1,I)),
		   add(lists:keyfind(apps,1,I)),
		   add(lists:keyfind(test_files,1,I)),
		   ok;
	       {error,Err} ->
		   {error,Err}
	   end,
    Result.

add({Key,Value})->
    ets:match_delete(?ETS,{Key,Value}),
    ets:insert(?ETS,{Key,Value}).


delete(Key)->
    ets:match_delete(?ETS,{Key,'_'}).

get(Key)->
   Result=case ets:match_object(?ETS, {Key,'$1'}) of
	      []->
		  [];
	      Info ->
		  Info
	  end,
    Result.

all()->
    ets:tab2list(?ETS).

test_ets()->
    [{computers,
      [{"master_computer",'master_computer@asus',"localhost",42000},
       {"w1_computer",'w1_computer@asus',"localhost",42001},
       {"w2_computer",'w2_computer@asus',"localhost",42002}]}
    ]=system_test:get(computers),
    [{lib_service,[{{service,"lib_service"},{dir,"/home/pi/erlang/c/source"}}]}]=system_test:get(lib_service),
    
    [{apps,[{{service,"dns_service"},{dir,"/home/pi/erlang/c/source"},
	     {computer,"master_computer"}},{{service,"iaas_service"},
					    {dir,"/home/pi/erlang/c/source"},
					    {computer,"master_computer"}}]}
    ]=system_test:get(apps),
    [{test_files,[{infrastructure,stop}]}]=system_test:get(test_files),
    ok.
