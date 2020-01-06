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
    
    {ok,_Pid}=master_service:start(),
    ["machine_w2@asus","machine_w3@asus","machine_w1@asus"]=iaas_service:active_machines(),
    ok.

%----- node config --------------------------------------------------------

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
	 {service_def,_}]}=etcd_lib:read_catalogue(new_test_app),
    {ok,[{specification,new_test_2_app},
	 {type,application},
	 {description,"Specification file for application template"},
	 {vsn,"1.0.0"},
	 {service_def,_}]}=etcd_lib:read_catalogue(new_test_2_app),
    {error,[no_app_specs,etcd_lib,_]}=etcd_lib:read_catalogue(new_test_glurk_app),
    ok.

etcd_machine_spec_test()->
    {ok,Machines}=etcd_lib:read_machines(),
%    glurk=Machines,
    true=lists:keymember({machine_id,"machine_m1@asus"},1,Machines),
    true=lists:keymember({machine_id,"machine_w1@asus"},1,Machines),
    false=lists:keymember({machine_id,"machine_glurk@asus"},1,Machines),
%------------------------------------------------------------------------
    
    {ok,Machine}=etcd_lib:read_machines("machine_m1@asus"),
    {{machine_id,"machine_m1@asus"},
     {ip_addr,"localhost",10000},
     {zone,"sthlm.flat.room1"},
     {capabilities,[disk,tellstick]}}=Machine,
    {ok,Machine2}=etcd_lib:read_machines("machine_w1@asus"),
    {{machine_id,"machine_w1@asus"},
     {ip_addr,"localhost",20000},
     {zone,"varmdoe.main.room2"},
     {capabilities,[]}}=Machine2,
    {error,[no_machine_info,etcd_lib,_98]}=etcd_lib:read_machines("machine_glurk@asus"),
    ok.
    
%----- master test 1  tests----------------------------------------------------
spec_1_test()->
    {ok,new_test_app,
     [{specification,new_test_app},
      {type,application},
      {description,"Specification file for application template"},
      {vsn,"1.0.0"},
      {service_def,[[{service,"t1_service"},{dir,path_t1_service},{machine,"machine_w1@asus"}],
		    [{service,"t2_service"},{git,url_t2_service},{machine,[]}],
		    [{service,"t1_service"},{dir,path_t1_service},{machine,"machine_w1@asus"}]]}]}=spec:read(?NEW_TEST_APP_SPEC),
  
    ok.
 
spec_2_test()->   
    new_test_app=spec:read(specification,?NEW_TEST_APP_SPEC),
    application=spec:read(type,?NEW_TEST_APP_SPEC),
    "Specification file for application template"=spec:read(description,?NEW_TEST_APP_SPEC),
    "1.0.0"=spec:read(vsn,?NEW_TEST_APP_SPEC),
    ServiceDef=spec:read(service_def,?NEW_TEST_APP_SPEC),  
    [[{service,"t1_service"},{dir,path_t1_service},{machine,"machine_w1@asus"}],
     [{service,"t2_service"},{git,url_t2_service},{machine,[]}],
     [{service,"t1_service"},{dir,path_t1_service},{machine,"machine_w1@asus"}]]=ServiceDef,  	
    ok.

spec_3_test()->   
    new_test_2_app=spec:read(specification,?NEW_TEST_2_APP_SPEC),
    application=spec:read(type,?NEW_TEST_APP_SPEC),
    "Specification file for application template"=spec:read(description,?NEW_TEST_2_APP_SPEC),
    "1.0.0"=spec:read(vsn,?NEW_TEST_2_APP_SPEC),
    ServiceDef=spec:read(service_def,?NEW_TEST_2_APP_SPEC),  
    [[{service,"t1_service"},{dir,path_t1_service},{machine,"machine_w1@asus"}],
     [{service,"t2_service"},{git,url_t2_service},{machine,[]}],
     [{service,"t1_service"},{dir,path_t1_service},{machine,"machine_w2@asus"}],
     [{service,"t3_service"},{dir,path_t2_service},{machine,"machine_m1@asus"}]]=ServiceDef,  	
    ok.
    

%----- iaas tests---------------------------------------------------------
iaas_t1_test()->
    timer:sleep(2000),
    {ok,["machine_m1@asus",
	 "machine_m2@asus",
	 "machine_w2@asus",
	 "machine_w3@asus",
	 "machine_w1@asus"]}=iaas_service:get_all_nodes(),
    
    ok.

iaas_t2_test()->
    {error,[eexits,glurk@asus,iaas_service,_]}=iaas_service:machine_capabilities(glurk@asus),
    {ok,[{"machine_w2@asus",[]}]}=iaas_service:machine_capabilities(machine_w2@asus),
    {ok,[{"machine_w3@asus",L1}]}=iaas_service:machine_capabilities(machine_w3@asus),
    {true,true}={lists:member(disk,L1),lists:member(drone,L1)},
    {ok,[{"machine_m1@asus",L2}]}=iaas_service:machine_capabilities(machine_m1@asus),
    {true,true}={lists:member(disk,L2),lists:member(tellstick,L2)},
    ok.

iaas_machines_2_test()->
    ["machine_w2@asus","machine_w3@asus","machine_w1@asus"]=iaas_service:active_machines(),
    ["machine_m1@asus","machine_m2@asus"]=iaas_service:inactive_machines(),
    ok.



    


stop_test()->
    [pod:delete(node(),PodId)||PodId<-?POD_ID],
  %  iaas_service:stop(),
    master_service:stop(),
    do_kill().
do_kill()->
    init:stop().

%% --------------------------------------------------------------------
%% Function:create_worker_node(Service,MachineNode)
%% Description:
%% Returns:{ok,PidService}|{error,Err}
%% --------------------------------------------------------------------
  
