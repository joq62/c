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
-ifdef(unit_test).
-define(EXPIRED_TIME,1*1000).
-else.
-define(EXPIRED_TIME,50*1000).
-endif.

%% External exports
-export([init/0,add/4,delete/4,delete/5,
	 clear/0,get/1,
	 delete_expired/0,expired/0,
	 all/0
	]).

%-compile(export_all).




%% ====================================================================
%% External functions
%% ====================================================================
%% --------------------------------------------------------------------
%% Function: 
%% Description:
%% Returns: non
%% --------------------------------------------------------------------
init()->
    ?DNS_ETS=ets:new(?DNS_ETS,[public,bag,named_table]).

add(ServiceId,IpAddr,Port,Pod)->
    T=erlang:system_time(second),    
    ets:match_delete(?DNS_ETS,{ServiceId,IpAddr,Port,Pod,'_'}),
    ets:insert(?DNS_ETS,{ServiceId,IpAddr,Port,Pod,T}).

delete(ServiceId,IpAddr,Port,Pod)->
    ets:match_delete(?DNS_ETS,{ServiceId,IpAddr,Port,Pod,'_'}).

delete(ServiceId,IpAddr,Port,Pod,Time)->
    ets:match_delete(?DNS_ETS,{ServiceId,IpAddr,Port,Pod,Time}).

clear()->
    L=ets:match(?DNS_ETS,'$1'),
    [ets:match_delete(?DNS_ETS,{ServiceId,IpAddr,Port,Pod,Time})||[{ServiceId,IpAddr,Port,Pod,Time}]<-L].

get(ServiceId)->
   Result=case ets:match(?DNS_ETS, {ServiceId,'$1','$2','$3','_'}) of
	      []->
		  [];
	      Info ->
		  Info
	  end,
    Result.

delete_expired()->
    Exp=expired(),
    R=[delete(ServiceId,IpAddr,Port,Pod,Time)||{ServiceId,IpAddr,Port,Pod,Time}<-Exp],
    R.
expired()->
    L= all(),
    NewTime=erlang:system_time(second),
  %  Exp=[{ServiceId,IpAddr,Port,Pod,Time,(NewTime-Time)}||{ServiceId,IpAddr,Port,Pod,Time}<-L,?EXPIRED_TIME<(NewTime-Time)],
    Exp=[{ServiceId,IpAddr,Port,Pod,Time}||{ServiceId,IpAddr,Port,Pod,Time}<-L,?EXPIRED_TIME=<(NewTime-Time)],

    Exp.

all()->
    ets:tab2list(?DNS_ETS).

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
