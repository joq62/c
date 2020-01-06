%%% -------------------------------------------------------------------
%%% Author  : uabjle
%%% Description : dbase using dets 
%%%
%%% Created : 10 dec 2012
%%% -------------------------------------------------------------------
-module(test_master_service).
 
%% --------------------------------------------------------------------
%% Include files
%% --------------------------------------------------------------------
-include_lib("eunit/include/eunit.hrl").

%% --------------------------------------------------------------------
-define(CATALOGE,"/home/pi/erlang/c/catalogue").
-define(ETCD_INIT_FILE,"etcd_initial.config").

-define(MACHINE_LIST,["machine_m1@asus","machine_m2@asus","machine_w1@asus","machine_w2@asus","machine_w3@asus"]).
-define(POD_ID,["machine_w1","machine_w2","machine_w3"]).

-define(W1,'worker_1@asus').
-define(W2,'worker_2@asus').
-define(NEW_TEST_APP_SPEC,"new_test_app.spec").
-define(NEW_TEST_2_APP_SPEC,"new_test_2_app.spec").

-define(LIB_SERVICE_SPEC,"lib_service.spec").
-define(NODES_CONFIG,"nodes.config").
%% External exports

-export([]).


%% ====================================================================
%% External functions
%% ====================================================================
%% --------------------------------------------------------------------
%% Function:init 
%% Description:
%% Returns: non
%% --------------------------------------------------------------------
init_test()->
    [pod:delete(node(),PodId)||PodId<-?POD_ID],
    _Pods=[pod:create(node(),PodId)||PodId<-?POD_ID],
    ok=etcd_lib:init(?ETCD_INIT_FILE),
  %  {ok,_Pid}=master_service:start(),
   % ["machine_w2@asus","machine_w3@asus","machine_w1@asus"]=iaas_service:active_machines(),
    ok.

 

%%--------------- etcd-catalog
store_catalog_apps_test()->
    {ok,I}=file:consult(?ETCD_INIT_FILE),
    [{_Type,Path}]=proplists:get_value(app_specs,I),
    {ok,FileNames}=file:list_dir(Path),
    A=[file:consult(filename:join(Path,FileName))||FileName<-FileNames,".spec"==filename:extension(FileName)],
    
    AppSpecList=[{proplists:get_value(specification,Info),
		  proplists:get_value(vsn,Info),
		  proplists:get_value(machine,Info),
		  proplists:get_value(services,Info)}||{ok,Info}<-A],
  %  glurk=AppSpecList,
    [etcd_lib:create_catalog(AppId,Vsn,Machine,Services)||{AppId,Vsn,Machine,Services}<-AppSpecList],
    
    ok.

read_catalog_apps_test()->
    {ok,[[new_test_app,"1.0.0","machine_w1@asus",
	  [{{service,"t1_service"},{dir,path_t1_service}},
	   {{service,"t2_service"},{url,url_t2_service}}]]]}=etcd_lib:read_catalog(appid,new_test_app),

    {ok,_}=etcd_lib:read_catalog(machine,any),

    {error,[wrong_type,glurk,etcd_lib,_113]}=etcd_lib:read_catalog(glurk,any),

    {error,[no_info,etcd_lib,_120]}=etcd_lib:read_catalog(machine,glurk),
    ok.

%%-------- etcd-wanted--------------------

store_wanted_apps_test()->
    {ok,I}=file:consult(?ETCD_INIT_FILE),
    [{_Type,Path}]=proplists:get_value(app_specs,I),
    {ok,FileNames}=file:list_dir(Path),
    A=[file:consult(filename:join(Path,FileName))||FileName<-FileNames,".spec"==filename:extension(FileName)],
    
    AppSpecList=[{proplists:get_value(specification,Info),
		  proplists:get_value(vsn,Info),
		  proplists:get_value(machine,Info),
		  proplists:get_value(services,Info)}||{ok,Info}<-A],
  %  glurk=AppSpecList,
    [etcd_lib:create_wanted(AppId,Vsn,Machine,Services)||{AppId,Vsn,Machine,Services}<-AppSpecList],
    
    ok.

read_wanted_apps_test()->
    {ok,[[new_test_app,"1.0.0","machine_w1@asus",
	  [{{service,"t1_service"},{dir,path_t1_service}},
	   {{service,"t2_service"},{url,url_t2_service}}]]]}=etcd_lib:read_wanted(appid,new_test_app),

    {ok,_}=etcd_lib:read_wanted(machine,any),

    {error,[wrong_type,glurk,etcd_lib,_113]}=etcd_lib:read_wanted(glurk,any),

    {error,[eexists,machine,glurk,etcd_lib,_184]}=etcd_lib:read_wanted(machine,glurk),
    ok.

update_wanted_apps_test()->
    {ok,[[new_test_app,"1.0.0","machine_w1@asus",
	  [{{service,"t1_service"},{dir,path_t1_service}},
	   {{service,"t2_service"},{url,url_t2_service}}]]]}=etcd_lib:read_wanted(appid,new_test_app),

    %% Change Machines and Services
    true=etcd_lib:update_wanted(new_test_app,"1.0.0",new_machine,[services]),
    {ok,[[new_test_app,"1.0.0",new_machine,[services]]]}=etcd_lib:read_wanted(appid,new_test_app),
    ok.

delete_wanted_test()->
    {ok,[[new_test_app,"1.0.0",new_machine,[services]]]}=etcd_lib:read_wanted(appid,new_test_app),
    true=etcd_lib:delete_wanted(new_test_app,"1.0.0"),
    {error,[eexists,appid,new_test_app,etcd_lib,_184]}= etcd_lib:read_wanted(appid,new_test_app),

    etcd_lib:create_wanted(new_test_app,"1.0.0","machine_w1@asus",
			   [{{service,"t1_service"},{dir,path_t1_service}},
			    {{service,"t2_service"},{url,url_t2_service}}]),
    {ok,[[new_test_app,"1.0.0","machine_w1@asus",
	  [{{service,"t1_service"},{dir,path_t1_service}},
	   {{service,"t2_service"},{url,url_t2_service}}]]]}=etcd_lib:read_wanted(appid,new_test_app),
    ok.


%%--------------- etcd- deployment ------------------------------------------------------
create_deployment_test()->
    {ok,ListOfWantedApps}=etcd_lib:read_wanted(all),
  %  [WantedApp|_T]=ListOfWantedApps,
  %  [AppId,Vsn,Machine,ServiceList]=WantedApp,

%{{service,"t1_service"},{dir,path_t1_service}}
    %% 
    
    create_dep(ListOfWantedApps,pod_1,container_1,timestamp_1),
    
    ok.
%% Support function
create_dep([],_Pod,_Container,_TimeStamp)->
    ok;
create_dep([[AppId,Vsn,Machine,ServiceList]|T],Pod,Container,TimeStamp)->
    [etcd_lib:create_deployment(AppId,Vsn,Machine,Pod,Container,Service,TimeStamp)||
	{{service,Service},_}<-ServiceList],
    create_dep(T,Pod,Container,TimeStamp).
    
read_deployment_test()->
    {ok,_DeployedApps}=etcd_lib:read_deployment(all), 
    {ok,_}=etcd_lib:read_deployment(machine,any),
    [pod_1,pod_1]=blueprints:find_service("t1_service"),
    {error,[no_machine_info,etcd_lib,_262]}=blueprints:find_service(glurk),
    ok.

missing_apps_test()->
    etcd_lib:create_wanted(missing_app,"1.0.2",machine, [missingServices]),
    etcd_lib:create_deployment(deprechiated_app,"2.0.1",machine_dep,pod_dep,cont_dep,service_dep,timestamp_dep),
    [{missing_app,"1.0.2"}]=blueprints:missing_apps(),
    ok.

deprechiated_apps_test()->
    [{deprechiated_app,"2.0.1"}]=blueprints:deprechiated_apps(),
    ok.
%%---------------- etcd -MACHINE --------------------------

machines_test()->
    [blueprints:create_machine_by_id(MachineId,passive)||MachineId<-?MACHINE_LIST],
    AllMachines=blueprints:read_machine(all),
    true=lists:member({machine,machine_m2@asus,passive},AllMachines),
    [passive]=blueprints:read_machine_by_id("machine_w3@asus"),
    [passive]=blueprints:read_machine('machine_w3@asus'),
    blueprints:update_machine_by_id("machine_w3@asus",active),
    {ok,[[machine_w3@asus,active]]}=blueprints:read_machine('machine_w3@asus'),
   
    {ok,[[machine_w3@asus,active]]}=blueprints:read_machine(status,active),
    {ok,_}=blueprints:read_machine(status,passive),
    ok.




stop_test()->
    [pod:delete(node(),PodId)||PodId<-?POD_ID],
  %  iaas_service:stop(),
  %  master_service:stop(),
    do_kill().
do_kill()->
    init:stop().

%% --------------------------------------------------------------------
%% Function:create_worker_node(Service,MachineNode)
%% Description:
%% Returns:{ok,PidService}|{error,Err}
%% --------------------------------------------------------------------
  
