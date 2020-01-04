%%% -------------------------------------------------------------------
%%% Author  : uabjle
%%% Description : dbase using dets 
%%%
%%% Created : 10 dec 2012
%%% -------------------------------------------------------------------
-module(infrastructure). 
  
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

    [{computers,ComputerList}]=system_test:get(computers),
    [{lib_service,LibService}]=system_test:get(lib_service),
    PodList=[{pod:create(node(),ComputerId),ComputerId}||{ComputerId,_Computer,_IpAddr,_Port}<-ComputerList],
    PongList=[rpc:call(node(),net_adm,ping,[Computer])||{{ok,Computer},_ComputerId}<-PodList],
	  % Check if all are pong
    true=lists:flatlength(PongList)==lists:flatlength([pong||pong<-PongList]),
	  % Pods running and ok 
    
	  % Start lib_service on all nodes
    [container:create(Computer,ComputerId,LibService)||{{ok,Computer},ComputerId}<-PodList],
          %Check if lib_service started on all 
    LibServicePing=[rpc:call(Computer,lib_service,ping,[],2000)||{{ok,Computer},_ComputerId}<-PodList],
    true=lists:flatlength(LibServicePing)==lists:flatlength([pong||{pong,_,lib_service}<-LibServicePing]),
          %Lib_service OK  

          % Allocate a tcp Server per Computer
    
    [rpc:call(Computer,lib_service,start_tcp_server,[IpAddr,Port,parallell])||{_ComputerId,Computer,IpAddr,Port}<-ComputerList],
    TcpServerPing=[rpc:call(node(),tcp_client,call,[{IpAddr,Port},{lib_service,ping,[]}])||{_ComputerId,_Computer,IpAddr,Port}<-ComputerList],
    true=lists:flatlength(TcpServerPing)==lists:flatlength([pong||{pong,_,lib_service}<-TcpServerPing]), 
    % computers started and lib_service installed

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
