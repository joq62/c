%%% -------------------------------------------------------------------
%%% Author  : uabjle
%%% Description : dbase using dets 
%%%
%%% Created : 10 dec 2012
%%% -------------------------------------------------------------------
-module(test_iaas). 
  
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

start(Apps,Computers)->
    %% Get iaas computer and address
  %  glurk=Apps,
    [IaasComputerId]=[ComputerId||{{service,"iaas_service"},{dir,_},{computer,ComputerId}}<-Apps],
    {IaasComputerId,IaasComputer,IaasIpAddr,IaasPort}=lists:keyfind(IaasComputerId,1,Computers),
    
    %% add all computers
    R=add_check_status_computers(IaasComputerId,IaasComputer,IaasIpAddr,IaasPort,Computers),
    io:format("~p~n",[R]),
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
add_check_status_computers(_IaasComputerId,IaasComputer,IaasIpAddr,IaasPort,Computers)->
    [rpc:call(node(),tcp_client,call,[{IaasIpAddr,IaasPort},IaasComputer,{iaas_service,add,[IpAddr,Port,Computer,passive]}])
     ||{_ComputerId,Computer,IpAddr,Port}<-Computers],
    rpc:call(node(),tcp_client,call,[{IaasIpAddr,IaasPort},IaasComputer,{iaas_service,check_all_status,[]}]).

%**************************************************************
