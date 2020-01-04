%%% -------------------------------------------------------------------
%%% Author  : uabjle
%%% Description : dbase using dets 
%%%
%%% Created : 10 dec 2012
%%% -------------------------------------------------------------------
-module(infrastructure_test). 
  
%% --------------------------------------------------------------------
%% Include files
%% --------------------------------------------------------------------
% -include_lib("eunit/include/eunit.hrl").

%% --------------------------------------------------------------------

%% External exports
-export([start/0,
	 
	 stop/0
	]).

%-compile(export_all).

-define(TIMEOUT,1000*15).

%% ====================================================================
%% External functions
%% ====================================================================
% ComputerList=[{"master_computer",'master_computer@asus',"localhost",42000},
%  {"w1_computer",'w1_computer@asus',"localhost",42001},
%  {"w2_computer",'w2_computer@asus',"localhost",42002}]
% LibService=[{{service,"libservice_service"},{dir,"/home/pi/erlang/c/source"}}]
% AppList={{service,"iaas_service"},{dir,"/home/pi/erlang/c/source"},{computer,"master_computer",'master_computer@asus'}}

start()->
    io:format(" ~n"),
    io:format("~p",[time()]),
    io:format(" Test started :~p~n",[{?MODULE,start}]),
    io:format(" ~n"),
    test(5),

    io:format(" ~n"),
    io:format("~p",[time()]),
    io:format("  OK :~p~n",[{?MODULE,start}]),
    io:format(" ~n"),
    ok.
test(0)->
    ok;
test(N) ->
    io:format("N = ~p~n",[N]),
    rpc:call(node(),infrastructure,start,[]),
    timer:sleep(50),
    rpc:call(node(),infrastructure,stop,[]),
    timer:sleep(50),
    test(N-1).

stop()->
    io:format(" ~n"),
    io:format("~p",[time()]),
    io:format(" Test started :~p~n",[{?MODULE,stop}]),
    io:format(" ~n"),

    [{computers,ComputerList}]=system_test:get(computers),	
    [container:delete(Computer,ComputerId,["lib_service"])||{ComputerId,Computer,_,_}<-ComputerList],
    [pod:delete(node(),ComputerId)||{ComputerId,_Computer,_,_}<-ComputerList],
    PangList=[rpc:call(node(),net_adm,ping,[Computer])||{_ComputerId,Computer,_,_}<-ComputerList],
    true=lists:flatlength(PangList)==lists:flatlength([pang||pang<-PangList]),
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
