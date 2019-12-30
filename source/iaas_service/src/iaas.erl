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

-compile(export_all).
%% ====================================================================
%% External functions
%% ===================================================================
init()->
    ets:new(?IAAS_ETS, [bag, named_table]).
    

add(IpAddr,Port,PodC,Status)->
    ets:match_delete(?IAAS_ETS,{IpAddr,Port,PodC,Status}),
    ets:insert(?IAAS_ETS,{IpAddr,Port,PodC,Status}).

change_status(IpAddr,Port,PodC,NewStatus)->
    add(IpAddr,Port,PodC,NewStatus).

delete(IpAddr,Port,Pod)->
    ets:match_delete(?IAAS_ETS,{IpAddr,Port,Pod,'_'}).

delete(IpAddr,Port,Pod,Status)->
    ets:match_delete(?IAAS_ETS,{IpAddr,Port,Pod,Status}).

all()->
    ets:tab2list(?IAAS_ETS).

check_all_status()->
    L=all(),
    Result=case L of
	       []->
		   {error,no_computers_allocated};
	       L->
		   do_ping(L,[])		   
	   end,
    Result.

do_ping([],PingR)->
    PingR;
do_ping([{IpAddr,Port,Pod,_Status}|T],Acc) ->
    case tcp_client:connect(IpAddr,Port) of
	{error,Err}->
	    R={error,Err};
	PidSession->
	   % doesnt work!   rpc:call(node(),tcp_client,session_call,[PidSession,{net_adm,ping,[Pod]}],5000),
	  %  tcp_client:session_call(PidSession,Pod,{net_adm,ping,[Pod]}),
	    tcp_client:session_call(PidSession,Pod,{net_adm,ping,[Pod]}),
	    case tcp_client:get_msg(PidSession,1000) of
		pong->
		    R={ok,[IpAddr,Port,Pod]};
		pang->
		    R={error,[pang,IpAddr,Port,Pod,?MODULE,?LINE]};
		{badrpc,Err}->
		    R={badrpc,[IpAddr,Port,Pod,Err,?MODULE,?LINE]};
		Err->
		    R={error,[Err,IpAddr,Port,Pod,?MODULE,?LINE]}
	    end,
	    tcp_client:disconnect(PidSession)
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


