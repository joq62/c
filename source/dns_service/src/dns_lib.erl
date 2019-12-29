%%% -------------------------------------------------------------------
%%% Author  : uabjle
%%% Description : dbase using dets 
%%%
%%% Created : 10 dec 2012
%%% -------------------------------------------------------------------
-module(dns_lib).
 


%% --------------------------------------------------------------------
%% Include files
%% --------------------------------------------------------------------

%% --------------------------------------------------------------------
%-record(dns,{service_id,ip_addr,port,vm,timestamp}).
-define(DNS_ETS,dns_ets).
-define(EXPIRED_TIME,1).
%% External exports
-compile(export_all).

%-export([load_start_node/3,stop_unload_node/3
%	]).


%% ====================================================================
%% External functions
%% ====================================================================
%% --------------------------------------------------------------------
%% Function: 
%% Description:
%% Returns: non
%% --------------------------------------------------------------------
init()->
    ?DNS_ETS=ets:new(?DNS_ETS,[bag,named_table]).

add(ServiceId,IpAddr,Port,Pod)->
    T=erlang:system_time(second),    
    ets:match_delete(?DNS_ETS,{ServiceId,IpAddr,Port,Pod,'_'}),
    ets:insert(?DNS_ETS,{ServiceId,IpAddr,Port,Pod,T}).

delete(ServiceId,IpAddr,Port,Pod)->
    ets:match_delete(?DNS_ETS,{ServiceId,IpAddr,Port,Pod,'_'}).

get(ServiceId)->
   Result=case ets:match(?DNS_ETS,{ServiceId,'$1','$2','$3','_'}) of
	      []->
		  [];
	      Info ->
		  Info
	  end,
    Result.


expired()->
    L=ets:match(?DNS_ETS,'$1'),
    NewTime=erlang:system_time(second),
 %   Exp=[ets:match_delete(?DNS_ETS,{ServiceId,IpAddr,Port,Pod,'_'})||[{ServiceId,IpAddr,Port,Pod,Time}]<-L,?EXPIRED_TIME<(NewTime-Time)],
    Exp=[{ServiceId,IpAddr,Port,Pod,Time}||[{ServiceId,IpAddr,Port,Pod,Time}]<-L,?EXPIRED_TIME<(NewTime-Time)],
%    [ets:match_delete(?DNS_ETS,{ServiceId,IpAddr,Port,Pod,Time})||{ServiceId,IpAddr,Port,Pod,Time}<-Exp].
    expired(Exp).
expired([])->
    ok;
expired([{ServiceId,IpAddr,Port,Pod,Time}|T])->
    io:format("~p~n",[{ServiceId,IpAddr,Port,Pod,Time,?MODULE,?LINE}]),
    ets:delete_object(?DNS_ETS,{ServiceId,IpAddr,Port,Pod,Time}),
    expired(T).
all()->
    ets:match(?DNS_ETS,'$1').

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

%% --------------------------------------------------------------------
%% Function: 
%% Description:
%% Returns: non
%% --------------------------------------------------------------------
