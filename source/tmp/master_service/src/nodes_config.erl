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
	 wanted_state_nodes/1,wanted_state_services/1,
	 create_ets_list/2,
	 ip_addr/1,ip_addr/2,
	 zone/0,zone/1,capability/1
	]).


%% ====================================================================
%% External functions
%% ====================================================================
%% --------------------------------------------------------------------
%% Function: 
%% Description:
%% Returns: non
%% --------------------------------------------------------------------

wanted_state_nodes(ConfigFile)->
    Result = case file:consult(ConfigFile) of
		 {ok,I}->
		     [{NodeStr,list_to_atom(NodeStr)}||NodeStr<-I];
		 {error,Err}->
		     {error,[Err,ConfigFile,?MODULE,?LINE]}
	     end,
    Result.

wanted_state_services(JoscaDir)->
    
    Result = case file:list_dir(JoscaDir) of
		 {ok,Files}->
		     read_josca(Files,JoscaDir,[]);
		 {error,Err}->
		     {error,[Err,JoscaDir,?MODULE,?LINE]}
	     end,
    Result.

read_josca([],_JoscaDir,WantedStateServices)->
    WantedStateServices;
read_josca([File|T],JoscaDir,Acc)->
    {ok,I}=file:consult(filename:join(JoscaDir,File)),
 %   {application_id,AppId}=lists:keyfind(application_id,1,I),
 %   {vsn,Vsn}=lists:keyfind(vsn,1,I),
    {services,ServiceSpecs}=lists:keyfind(services,1,I),
    ServiceList=[{Service,Num,NodeStr}||{{service,Service},{num_instances,Num},{node_str,NodeStr}}<-ServiceSpecs],
    NewAcc=lists:append(ServiceList,Acc),
    read_josca(T,JoscaDir,NewAcc).
    
    

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
			     ets:new(?NODES_ETS, [set, named_table]),
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
    Caps=[{{Cap,N},Cap,N}||Cap<-C],
    Zone=[{{zone,N},Z,N}],
    Status=[{{S,N},S,N}],
    NewAcc=lists:append([Caps,Zone,IpAddress_Port,Status,Acc]),
    create_ets_list(T,NewAcc).

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
    Result=case  ets:match(?NODES_ETS,{{Capability,'$1'},'$2','_'}) of
	       []->
		   {ok,[]};
	       EtsResult->
		   A=[{Node,Capability1}||[Node,Capability1]<-EtsResult],
		   {ok,A}
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
