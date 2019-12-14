%%% -------------------------------------------------------------------
%%% Author  : uabjle
%%% Description : dbase using dets 
%%%
%%% Created : 10 dec 2012
%%% -------------------------------------------------------------------
-module(blueprints).
 
%% --------------------------------------------------------------------
%% Include files
%% --------------------------------------------------------------------


%% --------------------------------------------------------------------
%% External exports

-export([find_service/1,
	missing_apps/0,deprichiated_apps/0]).


%% ====================================================================
%% External functions
%% ====================================================================
%% --------------------------------------------------------------------
%% Function:init 
%% Description:
%% Returns: non
%% --------------------------------------------------------------------
find_service(Service)->
    Result=case etcd_lib:read_deployment(service,Service) of
	       {error,Err}->
		   {error,Err};
	       {ok,ListOfServices}->
		   [Pod||[_AppId,_Vsn,_Machine,Pod,_Container,_Service,_TimeStamp]<-ListOfServices]
	   end,
    Result.


missing_apps()->
    {ok,DeployedApps}=etcd_lib:read_deployment(all),
    {ok,WantedApps}=etcd_lib:read_wanted(all),
    FilteredDeployedApps=remove_double(DeployedApps,[]),
    MissingApps=[{WantedAppId,WantedVsn}||[WantedAppId,WantedVsn,_,_]<-WantedApps,
					  false==lists:member({WantedAppId,WantedVsn},FilteredDeployedApps)],
%                                            {{service,"t2_service"},{url,url_t2_service}}]
%    {"Missing = ",MissingApps, " DeployedApps =",DeployedApps,
 %    ' FilteredDeployedApps=  ',FilteredDeployedApps}.    
    MissingApps.

deprichiated_apps()->
  {ok,DeployedApps}=etcd_lib:read_deployment(all),
    {ok,WantedApps}=etcd_lib:read_wanted(all),
    FilteredWantedApps=[{WantedAppId,WantedVsn}||[WantedAppId,WantedVsn,_,_]<-WantedApps],
    FilteredDeployedApps=remove_double(DeployedApps,[]),
    DepApps=[{DepAppId,DepVsn}||{DepAppId,DepVsn}<-FilteredDeployedApps,
				      false==lists:member({DepAppId,DepVsn},FilteredWantedApps)],
    
    DepApps.

remove_double([],DoubleRemoved)->
    DoubleRemoved;
remove_double([[AppId,Vsn,_,_,_,_,_]|T],Acc)->
    NewAcc=case lists:member({AppId,Vsn},Acc) of
	       false->
		   [{AppId,Vsn}|Acc];
	       true->
		   Acc
	   end,
    remove_double(T,NewAcc).

%%
%  [[new_test_app,"1.0.0","machine_w1@asus",pod_1,container_1,"t2_service",timestamp_1],
%   [new_test_2_app,"1.0.0",any,pod_1,container_1,"t3_service",timestamp_1],
%   [new_test_2_app,"1.0.0",any,pod_1,container_1,"t1_service",timestamp_1],
%   [new_test_app,"1.0.0","machine_w1@asus",pod_1,container_1,"t1_service",timestamp_1]],
  
 %        ' WantedApps= ',
%  [[new_test_app,"1.0.0","machine_w1@asus",[{{service,"t1_service"},{dir,path_t1_service}},
%                                            {{service,"t2_service"},{url,url_t2_service}}]],
%   [new_test_2_app,"1.0.0",any,[{{service,"t1_service"},{dir,path_t1_service}},
%                                 {{service,"t3_service"},{url,url_t3_service}}]]]
