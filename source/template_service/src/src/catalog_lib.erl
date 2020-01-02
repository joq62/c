%%% -------------------------------------------------------------------
%%% Author  : uabjle
%%% Description : dbase using dets 
%%%
%%% Created : 10 dec 2012
%%% -------------------------------------------------------------------
-module(catalog_lib).
 


%% --------------------------------------------------------------------
%% Include files
%% --------------------------------------------------------------------

%% --------------------------------------------------------------------
%-record(dns,{service_id,ip_addr,port,vm,timestamp}).
-define(ETS,catalog_ets).
-define(EXPIRED_TIME,1).
%% External exports
-export([init/0,add/1,
	 clear/0,delete/2,delete/5,
	 get/2,
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
    ?ETS=ets:new(?ETS,[bag,named_table]).

add(AppSpec)->
    [{app,App},{description,Desc},{vsn,Vsn},
     {machine,Machine},{services,Services}]=AppSpec,
    ets:match_delete(?ETS,{app_spec,App,'_',Vsn,'_','_'}),
    ets:insert(?ETS,{app_spec,App,Desc,Vsn,Machine,Services}).

delete(App,Vsn)->
    ets:match_delete(?ETS,{app_spec,App,'_',Vsn,'_','_'}).

delete(ServiceId,IpAddr,Port,Pod,Time)->
    ets:match_delete(?ETS,{ServiceId,IpAddr,Port,Pod,Time}).

clear()->
    L=ets:match(?ETS,'$1'),
    [ets:match_delete(?ETS,{ServiceId,IpAddr,Port,Pod,Time})||[{ServiceId,IpAddr,Port,Pod,Time}]<-L].

get(App,Vsn)->
   Result=case ets:match_object(?ETS, {app_spec,App,'_',Vsn,'_','_'}) of
	      []->
		  [];
	      Info ->
		  Info
	  end,
    Result.

all()->
    ets:tab2list(?ETS).

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
