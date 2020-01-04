%%% -------------------------------------------------------------------
%%% Author  : uabjle
%%% Description : dbase using dets 
%%%
%%% Created : 10 dec 2012
%%% -------------------------------------------------------------------
-module(test_1). 
  
%% --------------------------------------------------------------------
%% Include files
%% --------------------------------------------------------------------
% -include_lib("eunit/include/eunit.hrl").
-include("test_src/common_macros.hrl").
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


start()->
    io:format(" ~n"),
    io:format("~p",[time()]),
    io:format(" Test started :~p~n",[{?MODULE,start}]),
    io:format(" ~n"),

    R=tcp_client:call(?DNS_ADDRESS,{dns_service,get,["adder_service"]}),
    io:format("adder_service ip :~p~n",[{?MODULE,R}]), 

    R1=tcp_client:call(?DNS_ADDRESS,{dns_service,all,[]}),
    io:format("iaas_service ip :~p~n",[{?MODULE,R1}]), 
 
    %---- Do a service call
    [[IP,Port,_]|_]=tcp_client:call(?DNS_ADDRESS,{dns_service,get,["adder_service"]}),
    R2=tcp_client:call({IP,Port},{adder_service,add,[12,30]}),
    io:format("12+30= ~p~n",[R2]), 
    [[IP2,Port2,_]|_]=tcp_client:call(?DNS_ADDRESS,{dns_service,get,["iaas_service"]}),
    R22=tcp_client:call({IP2,Port2},{iaas_service,all,[]}),
    io:format(" ~p~n",[R22]), 



    io:format(" ~n"),
    io:format("~p",[time()]),
    io:format("  OK :~p~n",[{?MODULE,start}]),
    io:format(" ~n"),
    ok.

stop()->
    io:format(" ~n"),
    io:format("~p",[time()]),
    io:format(" Test started :~p~n",[{?MODULE,stop}]),
    io:format(" ~n"),

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
