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
-define(ETCD_INIT_FILE,"etcd_initial.config").


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
    
  %  {ok,_Pid}=master_service:start(),
   % ["machine_w2@asus","machine_w3@asus","machine_w1@asus"]=iaas_service:active_machines(),
    ok.

%----- master test 0  tests------------------------------------------------

orch_1_test()->

    ok.


% ----- master_service test  tests---------------------------------------------
etcd_app_spec_test()->
    ok=etcd_lib:init(?ETCD_INIT_FILE),
    {ok,AppSpecs}=etcd_lib:read_catalogue(),
    true=lists:keymember(new_test_app,1,AppSpecs),
    true=lists:keymember(new_test_2_app,1,AppSpecs),
    false=lists:keymember(new_test_glurk_app,1,AppSpecs),
%---------------------------------------------------------
    {ok,[{specification,new_test_app},
	 {type,application},
	 {description,"Specification file for application template"},
	 {vsn,"1.0.0"},
	 {machine,"machine_w1@asus"},
	 {services,_}]}=etcd_lib:read_catalogue(new_test_app),
    {ok,[{specification,new_test_2_app},
	 {type,application},
	 {description,"Specification file for application template"},
	 {vsn,"1.0.0"},
	 {machine,any},
	 {services,_}]}=etcd_lib:read_catalogue(new_test_2_app),
    {error,[no_app_specs,etcd_lib,_]}=etcd_lib:read_catalogue(new_test_glurk_app),
    ok.

etcd_machine_spec_test()->
    {ok,Machines}=etcd_lib:all_machines(),
    ["machine_w2@asus","machine_m1@asus",
     "machine_w3@asus", 
     "machine_w1@asus","machine_m2@asus"]=Machines,
    true=etcd_lib:member("machine_m1@asus"),
    false=etcd_lib:member("machine_glurk@asus"),
    ok.
    
%----- master test 1  tests----------------------------------------------------
etcd_store_deployment_test()->
    ok=etcd_lib:store_deployment(appid_1,pod_1,cont_1,service1,machine1),
  %  glurk=etcd_lib:read_all(),
    {ok,[[appid_1,pod_1,cont_1,service1,machine1]]}=etcd_lib:deployment_info(all),
    ok=etcd_lib:store_deployment(appid_2,pod_2,cont_2,service2,machine2),
%    {ok,[[appid_1,pod_1,cont_1,service1,machine1],
%	 [appid_2,pod_2,cont_2,service2,machine2]]}=etcd_lib:deployment_info(all),
    
    {ok,[[appid_2,pod_2,cont_2,service2,machine2]]}=etcd_lib:deployment_info(appid,appid_2),
    {ok,[[appid_2,pod_2,cont_2,service2,machine2]]}=etcd_lib:deployment_info(pod,pod_2),
    {ok,[[appid_2,pod_2,cont_2,service2,machine2]]}=etcd_lib:deployment_info(container,cont_2),
    {ok,[[appid_2,pod_2,cont_2,service2,machine2]]}=etcd_lib:deployment_info(service,service2),
    {ok,[[appid_2,pod_2,cont_2,service2,machine2]]}=etcd_lib:deployment_info(machine,machine2),

    {error,[no_machine_info,etcd_lib,_100]}=etcd_lib:deployment_info(machine,glurk),
    {error,[wrong_type,glurk,etcd_lib,_93]}=etcd_lib:deployment_info(glurk,machine2),


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
  
