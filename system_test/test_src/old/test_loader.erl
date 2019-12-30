%%% -------------------------------------------------------------------
%%% Author  : uabjle
%%% Description : dbase using dets 
%%%
%%% Created : 10 dec 2012
%%% -------------------------------------------------------------------
-module(test_loader). 
  
%% --------------------------------------------------------------------
%% Include files
%% --------------------------------------------------------------------
% -include_lib("eunit/include/eunit.hrl").

%% --------------------------------------------------------------------

%% External exports
-compile(export_all).

-define(TIMEOUT,1000*15).

%% ====================================================================
%% External functions
%% ====================================================================
% ComputerList=[{"master_computer",'master_computer@asus',"localhost",42000},
%  {"w1_computer",'w1_computer@asus',"localhost",42001},
%  {"w2_computer",'w2_computer@asus',"localhost",42002}]
%
% AppList=[{{service,"iaas_service"},{dir,"/home/pi/erlang/c/source"},{computer,"master_computer",'master_computer@asus'}}]

start([],_Computers,_LibService)->
    io:format(" ~n"),
    io:format("~p",[time()]),
    io:format("  OK :~p~n",[{?MODULE,start}]),
    io:format(" ~n");
start([{{service,ServiceId},{Type,Source},{computer,ComputerId}}|T],Computers,LibService)->
    {ComputerId,Computer,IpAddr,Port}=lists:keyfind(ComputerId,1,Computers),
    %% Create Service pod @ computer!
    PodId="pod_"++ServiceId,
    {ok,Pod}=rpc:call(node(),tcp_client,call,[{IpAddr,Port},{pod,create,[node(),PodId]}]),
    pong=rpc:call(node(),tcp_client,call,[{IpAddr,Port},{net_adm,ping,[Pod]}]),
    % load lib_service 
    ok=rpc:call(node(),tcp_client,call,[{IpAddr,Port},Computer,{container,create,[Pod,PodId,LibService]}]),
    {pong,Pod,lib_service}=rpc:call(node(),tcp_client,call,[{IpAddr,Port},Pod,{lib_service,ping,[]}]),

    %create container with the service
    glurk=rpc:call(node(),tcp_client,call,[{IpAddr,Port},Pod,{container,create,[Computer,ComputerId,[{{service,ServiceId},{Type,Source}}]]}]),
    glurk=rpc:call(node(),tcp_client,call,[{IpAddr,Port},Computer,{application,loaded_applications,[]}]),

    Service=list_to_atom(ServiceId),
    {pong,Pod,Service}=rpc:call(node(),tcp_client,call,[{IpAddr,Port},Pod,{Service,ping,[]}]),
    % Container and service started OK
    start(T,Computers,LibService).

    
stop([],_Computers)->
    io:format(" ~n"),
    io:format("~p",[time()]),
    io:format("  OK :~p~n",[{?MODULE,stop}]),
    io:format(" ~n");
stop([{{service,ServiceId},{_Type,_Source},{computer,ComputerId}}|T],Computers)->
    {ComputerId,Computer,IpAddr,Port}=lists:keyfind(ComputerId,1,Computers),
    %% Create Service pod @ computer! 
    PodId="pod_"++ServiceId,
    Pod=rpc:call(node(),tcp_client,call,[{IpAddr,Port},{misc_lib,get_node_by_id,[PodId]}]),
    % test if succeded
   
    %delete container with the service
   % rpc:call(node(),tcp_client,call,[{IpAddr,Port},Pod,{container,delete,[Pod,PodId,[ServiceId]]}]),
   % pang=rpc:call(node(),tcp_client,call,[{IpAddr,Port},Pod,{list_to_atom(ServiceId),ping,[]}]),
    % Container and service started OK
    rpc:call(node(),tcp_client,call,[{IpAddr,Port},Computer,{pod,delete,[Pod,ServiceId]}]),
    stop(T,Computers).

%% --------------------------------------------------------------------
%% Function:init 
%% Description:
%% Returns: non
%% --------------------------------------------------------------------


%**************************************************************
