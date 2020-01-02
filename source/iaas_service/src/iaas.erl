%%% -------------------------------------------------------------------
%%% Author  : uabjle
%%% Description : dbase using dets 
%%%
%%% Created : 10 dec 2012
%%% -------------------------------------------------------------------
-module(iaas). 
  


%% --------------------------------------------------------------------
%% Include files
%% --------------------------------------------------------------------

%% --------------------------------------------------------------------
-define(IAAS_ETS,iaas_ets).

%% intermodule 
%% External exports
-export([init/0,add/4,
	 change_status/4,
	 delete/3,delete/4,
	 all/0,active/0,passive/0,
	 status/3,
	 check_all_status/0,change_status/1,
	 do_ping/2
       ]).

%-compile(export_all).
%% ====================================================================
%% External functions
%% ===================================================================
init()->
    ets:new(?IAAS_ETS, [bag, named_table]).
    

add(IpAddr,Port,PodC,Status)->
    ets:match_delete(?IAAS_ETS,{IpAddr,Port,PodC,'_'}),
    ets:insert(?IAAS_ETS,{IpAddr,Port,PodC,Status}).

change_status(IpAddr,Port,PodC,NewStatus)->
    add(IpAddr,Port,PodC,NewStatus).

delete(IpAddr,Port,Pod)->
    ets:match_delete(?IAAS_ETS,{IpAddr,Port,Pod,'_'}).

delete(IpAddr,Port,Pod,Status)->
    ets:match_delete(?IAAS_ETS,{IpAddr,Port,Pod,Status}).

all()->
    ets:tab2list(?IAAS_ETS).

active()->
    L=all(),
    [{IpAddr,Port,Pod}||{IpAddr,Port,Pod,Status}<-L,
			Status=:=active].

passive()->
    L=all(),
    [{IpAddr,Port,Pod}||{IpAddr,Port,Pod,Status}<-L,
			Status=:=passive].
status(IpAddr,Port,Pod)->
    L=all(),
    R=[Status||{IpAddr2,Port2,Pod2,Status}<-L,
	     {IpAddr2,Port2,Pod2}=:={IpAddr,Port,Pod}],
    case R of
	[]->
	    {error,[undef,IpAddr,Port,Pod]};
	[Status] ->
	    Status
    end.
    
check_all_status()->
    L=all(),
    Result=case L of
	       []->
		   {error,no_computers_allocated};
	       L->
		   AvaliableComputers=do_ping(L,[]),
		   change_status(AvaliableComputers),
		   AvaliableComputers
	   end,
    Result.

change_status([])->
    ok;
change_status([{ok,{IpAddr,Port,Pod},_Msg}|T])->
    change_status(IpAddr,Port,Pod,active),
    change_status(T);
change_status([{error,{IpAddr,Port,Pod},_Msg}|T])->
    change_status(IpAddr,Port,Pod,passive),
    change_status(T).

do_ping([],PingR)->
    PingR;
do_ping([{IpAddr,Port,Pod,_Status}|T],Acc) ->
    case tcp_client:connect(IpAddr,Port) of
	{error,Err}->
	    R={error,{IpAddr,Port,Pod},[?MODULE,?LINE,Err]};
	{ok,Socket}->
	   % doesnt work!   rpc:call(node(),tcp_client,session_call,[PidSession,{net_adm,ping,[Pod]}],5000),
	  %  tcp_client:session_call(PidSession,Pod,{net_adm,ping,[Pod]}),
	    tcp_client:cast(Socket,{net_adm,ping,[Pod]}),
	    case tcp_client:get_msg(Socket,1000) of
		pong->
		    R={ok,{IpAddr,Port,Pod},[]};
		pang->
		    R={error,{IpAddr,Port,Pod},[?MODULE,?LINE,pang]};
		{badrpc,Err}->
		    R={error,{IpAddr,Port,Pod},[?MODULE,?LINE,badrpc,Err]};
		Err->
		    R={error,{IpAddr,Port,Pod},[?MODULE,?LINE,Err]}
	    end,
	    tcp_client:disconnect(Socket)
      end,
    do_ping(T,[R|Acc]).
  
%% --------------------------------------------------------------------
%% Function:create_worker_node(Service,BoardNode)
%% Description:
%% Returns:{ok,PidService}|{error,Err}
%% --------------------------------------------------------------------

%% --------------------------------------------------------------------
%%% Internal functions
%% --------------------------------------------------------------------
%% --------------------------------------------------------------------
%% Function: unload_service(Service,BoardNode)
%% Description:
%% Returns:ok|{error,Err}
%% --------------------------------------------------------------------

%% --------------------------------------------------------------------
%% Function:stop_service_node(Service,WorkerNode)
%% Description:
%% Returns:ok|{error,Err}
%% --------------------------------------------------------------------


