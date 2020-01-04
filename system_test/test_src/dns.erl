%%% -------------------------------------------------------------------
%%% Author  : uabjle
%%% Description : dbase using dets 
%%%
%%% Created : 10 dec 2012
%%% -------------------------------------------------------------------
-module(dns). 
  
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
%
% AppList=[{{service,"iaas_service"},{dir,"/home/pi/erlang/c/source"},{computer,"master_computer"}}]

start()->
    io:format(" ~n"),
    io:format("~p",[time()]),
    io:format(" Test started :~p~n",[{?MODULE,start}]),
    io:format(" ~n"),
    
    % get dns ip addr
    {IpAddr,Port}=lib_service:dns_address(),
    % R=io:format("~p~n",[lib_service:dns_address()]),
    _R=rpc:call(node(),tcp_client,call,[{IpAddr,Port},{dns_service,ping,[]}]),
 %   io:format("~p~n",[R]),
    io:format(" ~n"),
    io:format("~p",[time()]),
    io:format("  OK :~p~n",[{?MODULE,start}]),
    io:format(" ~n").

stop()->
    
    io:format(" ~n"),
    io:format("~p",[time()]),
    io:format("  OK :~p~n",[{?MODULE,stop}]),
    io:format(" ~n").
%% --------------------------------------------------------------------
%% Function:init 
%% Description:
%% Returns: non
%% --------------------------------------------------------------------
