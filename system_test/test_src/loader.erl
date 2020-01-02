%%% -------------------------------------------------------------------
%%% Author  : uabjle
%%% Description : dbase using dets 
%%%
%%% Created : 10 dec 2012
%%% -------------------------------------------------------------------
-module(loader).  
  
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
% AppList=[{{service,"iaas_service"},{dir,"/home/pi/erlang/c/source"},{computer,"master_computer",'master_computer@asus'}}]
start()->
io:format(" ~n"),
    io:format("~p",[time()]),
    io:format(" Test started :~p~n",[{?MODULE,start}]),
    io:format(" ~n"),
    [{computers,Computers}]=system_test:get(computers),
    [{lib_service,LibService}]=system_test:get(lib_service),
    [{apps,Apps}]=system_test:get(apps),
    start(Apps,Computers,LibService).

start([],_Computers,_LibService)->
    io:format(" ~n"),
    io:format("~p",[time()]),
    io:format("  OK :~p~n",[{?MODULE,start}]),
    io:format(" ~n");
start([{{service,ServiceId},{Type,Source},{computer,ComputerId}}|T],Computers,LibService)->
    {ComputerId,Computer,IpAddr,Port}=lists:keyfind(ComputerId,1,Computers),
     %create container with the service
    ok=rpc:call(node(),tcp_client,call,[{IpAddr,Port},{container,create,[Computer,ComputerId,[{{service,ServiceId},{Type,Source}}]]}]),
    Service=list_to_atom(ServiceId),
    {pong,Computer,Service}=rpc:call(node(),tcp_client,call,[{IpAddr,Port},{Service,ping,[]}]),
    % Container and service started OK
    start(T,Computers,LibService).
%------------------------------------------------------------
stop()->
io:format(" ~n"),
    io:format("~p",[time()]),
    io:format(" Test started :~p~n",[{?MODULE,stop}]),
    io:format(" ~n"),
    [{lib_service,LibService}]=system_test:get(lib_service),
    [{apps,Apps}]=system_test:get(apps),
    stop(Apps,LibService).
stop([],_Computers)->
    io:format(" ~n"),
    io:format("~p",[time()]),
    io:format("  OK :~p~n",[{?MODULE,stop}]),
    io:format(" ~n");
stop([{{service,ServiceId},{_Type,_Source},{computer,ComputerId}}|T],Computers)->
    io:format("Apps :~p~n",[{?MODULE,ServiceId,ComputerId}]),
    {ComputerId,Computer,IpAddr,Port}=lists:keyfind(ComputerId,1,Computers),
    rpc:call(node(),tcp_client,call,[{IpAddr,Port},{container,delete,[Computer,ComputerId,[ServiceId]]}]),
    {badrpc,_}=rpc:call(node(),tcp_client,call,[{IpAddr,Port},{list_to_atom(ServiceId),ping,[]}]),
    % Container and service started OK
    stop(T,Computers).

%% --------------------------------------------------------------------
%% Function:init 
%% Description:
%% Returns: non
%% --------------------------------------------------------------------


%**************************************************************
