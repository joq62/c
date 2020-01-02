%%% -------------------------------------------------------------------
%%% Author  : uabjle
%%% Description : dbase using dets 
%%%
%%% Created : 10 dec 2012
%%% -------------------------------------------------------------------
-module(nodes_config).
  


%% --------------------------------------------------------------------
%% Include files
%% --------------------------------------------------------------------

%% --------------------------------------------------------------------
-define(NODES_ETS,node_config_ets).
%% External exports


-export([init/1,delete/0,
	 create_ets_list/2,
	 ip_addr/1,ip_addr/2,
	 zone/0,zone/1,capability/1,
	 get_all_nodes/0,
	 machine_capabilities/1
	]).


%% ====================================================================
%% External functions
%% ====================================================================
%% --------------------------------------------------------------------
%% Function: 
%% Description:
%% Returns: non
%% --------------------------------------------------------------------

%% --------------------------------------------------------------------
%% Function: 
%% Description:
%% Returns: non
%% --------------------------------------------------------------------
init(ConfigFile)->
    Result = case file:consult(ConfigFile) of
		 {ok,I}->
		    % io:format("~p~n",[{I,?MODULE,?LINE}]),
		     case rpc:call(node(),?MODULE,create_ets_list,[I,[]]) of
			 {badrpc,Err}->
			      {error,[badrpc,Err,create_ets_list,I,?MODULE,?LINE]};
			 EtsList->
			     ?NODES_ETS=ets:new(?NODES_ETS, [set, named_table]),
			     rpc:call(node(),ets,insert,[?NODES_ETS,EtsList])
		     end;
		 {error,Err}->
		     {error,[badrpc,Err,create_ets_listfile_consult,ConfigFile,?MODULE,?LINE]}
	     end,
    Result.


delete()->
    ets:delete(?NODES_ETS).

create_ets_list([],EtsList)->
    EtsList;
                
create_ets_list([{{node_id,N},{ip_addr,IpAddr,Port},{zone,Z},{capabilities,C},{status,S}}|T],Acc)->
    IpAddress_Port=[{{ip_addr,N},N,{IpAddr,Port}}],
    Caps=[{{cap,Cap,N},Cap,N}||Cap<-C],
    Zone=[{{zone,N},Z,N}],
    Status=[{{status,S,N},S,N}],
    NewAcc=lists:append([Caps,Zone,IpAddress_Port,Status,Acc]),
    create_ets_list(T,NewAcc).


get_all_nodes()->
     Result=case ets:match(?NODES_ETS,{{status,'_','_'},'$2','$1'}) of
	       []->
		   {error,[no_nodes,?MODULE,?LINE]};
	       Nodes->
		   A=[Node||[Node,_Status]<-Nodes],
		   {ok,A}
	   end,
    Result.

status(_Node)->
    ok.

status_active()->
    ok.
status_inactive()->
    ok.
set_status(_Node,_NewStatus)->
    ok.

zone()->
    Result=case ets:match(?NODES_ETS,{{zone,'$1'},'$2','_'}) of
	       []->
		   {error,[no_zones,?MODULE,?LINE]};
	       Zones->
		   A=[{Node,Zone}||[Node,Zone]<-Zones],
		   {ok,A}
	   end,
    Result.
	       
zone(NodeStr)->
    Result=case ets:match(?NODES_ETS,{{zone,NodeStr},'$2','_'}) of
	       []->
		   {error,[no_zones,?MODULE,?LINE]};
	       [[Zone]]->
		   {ok,Zone}
	   end,
    Result.

   
capability(Capability)->
    Result=case  ets:match(?NODES_ETS,{{cap,Capability,'$1'},'$2','_'}) of
	       []->
		   {ok,[]};
	       EtsResult->
		   A=[{Node,Capability1}||[Node,Capability1]<-EtsResult],
		   {ok,A}
	   end,
    Result.

machine_capabilities(MachineId)->
    Result=case  ets:match(?NODES_ETS,{{cap,'_',MachineId},'$1','$2'})of
	       []->
		   {ok,[{MachineId,[]}]};
	       EtsResult->
		   A=[Caps||[Caps,MId]<-EtsResult],
		   {ok,[{MachineId,A}]}
	   end,
    Result.

ip_addr(BoardId)->
    Result=case ets:match(?NODES_ETS,{{ip_addr,BoardId},'_',{'$3','$4'}}) of
	       []->
		   {error,[eexist,BoardId,?MODULE,?LINE]};
	       EtsResult->
		   A=[{IpAddr,Port}||[IpAddr,Port]<-EtsResult],
		   {ok,A}
	   end,
    Result.
ip_addr(IpAddr,Port)->
    Result=case ets:match(?NODES_ETS,{{ip_addr,'_'},'$1',{IpAddr,Port}}) of
	       []->
		   {error,[eexists,IpAddr,Port,?MODULE,?LINE]};
	       EtsResult->
		   A=[BoardId||[BoardId]<-EtsResult],
		   {ok,A}
	   end,
    Result.


%% --------------------------------------------------------------------
%% Function: 
%% Description:
%% Returns: non
%% --------------------------------------------------------------------
%filter_events(Key
