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
	 missing_apps/0,deprechiated_apps/0,
	 create_machine_by_id/2,create_machine/2,
	 update_machine_by_id/2,update_machine/2,
	 read_machine_by_id/1,read_machine/1,read_machine/2,
	 delete_machine_by_id/1,delete_machine/1
	]).


%% ====================================================================
%% External functions
%% ====================================================================

%% --------------------------------------------------------------------
%% Function:init 
%% Description:
%% Returns: non
%% --------------------------------------------------------------------
create_machine_by_id(MachineId,Status)-> % guard is atom 
    Machine=list_to_atom(MachineId),
    create_machine(Machine,Status).
create_machine(Machine,Status)->
    etcd_lib:create_machine(Machine,Status).

update_machine_by_id(MachineId,Status)->
    Machine=list_to_atom(MachineId),
    update_machine(Machine,Status).
update_machine(Machine,Status)->
    etcd_lib:update_machine(Machine,Status).

read_machine(all)->
    etcd_lib:read_machine(all);
read_machine(Machine)->    
    etcd_lib:read_machine(machine,Machine).


read_machine_by_id(MachineId)->
    read_machine(list_to_atom(MachineId)).

read_machine(status,Status)->
    etcd_lib:read_machine(status,Status).

delete_machine_by_id(MachineId)->
    Machine=list_to_atom(MachineId),
    delete_machine(Machine).
delete_machine(Machine)->
    etcd_lib:delete_machine(Machine).

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

%% --------------------------------------------------------------------
%% Function:init 
%% Description:
%% Returns: non
%% --------------------------------------------------------------------
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

%% --------------------------------------------------------------------
%% Function:init 
%% Description:
%% Returns: non
%% --------------------------------------------------------------------

deprechiated_apps()->
  {ok,DeployedApps}=etcd_lib:read_deployment(all),
    {ok,WantedApps}=etcd_lib:read_wanted(all),
    FilteredWantedApps=[{WantedAppId,WantedVsn}||[WantedAppId,WantedVsn,_,_]<-WantedApps],
    FilteredDeployedApps=remove_double(DeployedApps,[]),
    DepApps=[{DepAppId,DepVsn}||{DepAppId,DepVsn}<-FilteredDeployedApps,
				      false==lists:member({DepAppId,DepVsn},FilteredWantedApps)],
    
    DepApps.

%% --------------------------------------------------------------------
%% Function:init 
%% Description:
%% Returns: non
%% --------------------------------------------------------------------
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
