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
-define(POD_ID,["machine_w1","machine_w2","machine_w3"]).

-define(W1,'worker_1@asus').
-define(W2,'worker_2@asus').
-define(TEST_APP_SPEC,"test_app.spec").
-define(TEST_2_APP_SPEC,"test_2_app.spec").
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
    %    ok=master_service:load_chart(["test_app.spec"]),
    WantedApps=["test_app.spec"],
    StartedApps=[],
   [{ok,"test_app.spec",test_app,
     [{"t2_service",["machine_w1@asus"]},
      {"t3_service",["machine_w1@asus"]},
      {"t4_service",["machine_w1@asus"]},
      {"t1_service",["machine_w1@asus"]}]}]=master:get_start_list(WantedApps,StartedApps),

    [{ok,"test_app.spec",test_app,
      [{"t2_service",["machine_w3@asus"]},
       {"t3_service",["machine_w3@asus"]},
       {"t4_service",["machine_w3@asus"]},
       {"t1_service",
	["machine_w1@asus","machine_w3@asus","machine_w2@asus"]}]},
     {error,"test_2_app.spec",test_2_app,
      [{"lib_service",[]},{"node_controller_service",[]}]}]=master:get_start_list(["test_2_app.spec"|WantedApps],StartedApps),
    
    [{ok,"test_app.spec",test_app,
      [{"t2_service",["machine_w3@asus"]},
       {"t3_service",["machine_w3@asus"]},
       {"t4_service",["machine_w3@asus"]},
       {"t1_service",
	["machine_w1@asus","machine_w3@asus","machine_w2@asus"]}]}]=master:get_start_list(WantedApps,["test_2_app.spec"|StartedApps]),
    
    ok.


% ----- master_service test  tests---------------------------------------------
master_t1_test()->
    D0=date(),%T0=time(),
    [{D0,_,started,[]}]=master_service:get_log(),
    ok=master_service:load_chart(["test_app.spec"]),
    D1=date(),T1=time(),
    [{D1,T1,'applist loaded',[["test_app.spec"]]},
     {D0,T0,started,[]}]=master_service:get_log(),
    ok=master_service:update_chart(["test_app_2.spec"]),
    D2=date(),T2=time(),
    [{D2,T1,updated_applist,[["test_app_2.spec"]]},
     {D1,T1,'applist loaded',[["test_app.spec"]]},
     {D0,T0,started,[]}]=master_service:get_log(),
    ok=master_service:load_chart(["test_app.spec","test_app_again.spec","test_app_2.spec"]),
    D3=date(),T3=time(),
    [{D3,T3,
      'applist loaded',
            [["test_app.spec","test_app_again.spec","test_app_2.spec"]]},
     {D2,T2,updated_applist,[["test_app_2.spec"]]},
     {D1,T1,'applist loaded',[["test_app.spec"]]},
     {D0,T0,started,[]}]=master_service:get_log(),
    ok.
    
t2_test()->
%    ok=master_service:load_chart(["test_app.spec"]),
 %   ok=master_service:orchistrate(2000),

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

%----- master test 1  tests------------------------------------------------
spec_1_test()->
    {ok,test_app,
     [{specification,test_app},
      {type,application},
      {description,"Specification file for application template"},
      {vsn,"1.0.0"},
      {instances,1},
      {localization,[]},
      {service_def,[{"t1_service","t1.spec"}]}]}=spec:read(?TEST_APP_SPEC),
    {ok,lib_service,
    [{specification,lib_service},
     {type,service},
     {description,"Specification file for service"},
     {vsn,"1.0.0"},
     {exported_services,{"lib_service",any}},
     {needed_capabilities,[]},
     {dependencies,[]}]}=spec:read(?LIB_SERVICE_SPEC),
    
    ok.
 
spec_2_test()->   
    test_app=spec:read(specification,?TEST_APP_SPEC),
    application=spec:read(type,?TEST_APP_SPEC),
    "Specification file for application template"=spec:read(description,?TEST_APP_SPEC),
    "1.0.0"=spec:read(vsn,?TEST_APP_SPEC),
    1=spec:read(instances,?TEST_APP_SPEC),
    []=spec:read(localization,?TEST_APP_SPEC),
    [{"t1_service","t1.spec"}]=spec:read(service_def,?TEST_APP_SPEC),  
    ok.
    
spec_3_test()->
    lib_service=spec:read(specification,?LIB_SERVICE_SPEC),
    service=spec:read(type,?LIB_SERVICE_SPEC),
    "Specification file for service"=spec:read(description,?LIB_SERVICE_SPEC),
    "1.0.0"=spec:read(vsn,?LIB_SERVICE_SPEC),
    {"lib_service",any}=spec:read(exported_services,?LIB_SERVICE_SPEC),
    []=spec:read(needed_capabilities,?LIB_SERVICE_SPEC),
    []=spec:read(dependencies,?LIB_SERVICE_SPEC),
    ok.

apps_to_start_and_stop_1_test()->
    WantedApps=[?TEST_APP_SPEC,?TEST_2_APP_SPEC],
    ActiveApps=[{spec:read(specification,?TEST_APP_SPEC),
		 ?TEST_APP_SPEC,
		 [{lib_service,node_1}]},
		{app_glurk,
		 "glurk_app.spec",
		 [{another_service,node_1}]}],

    % 1) check if need to start a new application 
    AppsToStart=[AppSpec||AppSpec<-WantedApps,
			  false==lists:keymember(spec:read(specification,AppSpec),
						 1,ActiveApps)],
    ["test_2_app.spec"]=AppsToStart,

    % 2) Check if need to stop a existing application
    AppsToStop=[{AppSpec,ServiceInfo}||{_AppsId,AppSpec,ServiceInfo}<-ActiveApps,
			  false==lists:member(AppSpec,WantedApps)],
    [{"glurk_app.spec",[{another_service,node_1}]}]=AppsToStop,
    ok.
    
start_app_test()->
    WantedApps=["test_app.spec"],
    ActiveApps=[],
    AppsToStart=[AppSpec||AppSpec<-WantedApps,
			  false==lists:keymember(spec:read(specification,AppSpec),
						 1,ActiveApps)],
    []=[{AppSpec,ServiceInfo}||{_AppsId,AppSpec,ServiceInfo}<-ActiveApps,
				       false==lists:member(AppSpec,WantedApps)],
    AppsToStart,
    % In app spec need to specify service vsn 
    % Use github tag for versioning otherwise need store different versions ..
    % 
    ok.
node_app_test()->
    WantedApps=["test_app.spec","test_app_2.spec"],
  %  WantedApps=["test_app.spec"],
    ActiveApps=[],
    %% Get apps to start
    ServicesSpecsDependencies=master:get_services_dependendies(ActiveApps,WantedApps),
    [{"test_app.spec",1,[],
      [{"t1_service",[]},
       {"t4_service",[disk]},
       {"t3_service",[drone]},
       {"t2_service",[disk,drone]}]},
     {"test_app_2.spec",1,
      [board_w1@asus,board_m1@asus],
      [{"t10_service",[]}]}]= ServicesSpecsDependencies,
    
    %check if there are needs forspecific capabilities
    
    %%% Get availible nodes and allocate 
    %%% 
    ANodes=[{'board_m1@asus',[capa1]},{node(),[]},{'board_w1@asus',[capa1,capa2]}],
    Candidates=master:get_candidates(ServicesSpecsDependencies,ANodes),			 
    [{"test_app.spec",test_app,
      [{"t1_service",
	[board_w1@asus,test_master_service@asus,board_m1@asus]},
       {"t4_service",[]},
       {"t3_service",[]},
       {"t2_service",[]}]},
     {"test_app_2.spec",test_app_2,
      [{"t10_service",
	[board_w1@asus,test_master_service@asus,board_m1@asus]}]
     }]=Candidates,
    
%%% Check node contstrains and Choose nodes and buld start list
    FilterConstrains=master:filter_constrains(Candidates,ServicesSpecsDependencies),
[{"test_app_2.spec",test_app_2,
  [{"t10_service",[board_w1@asus,board_m1@asus]}]},
 {"test_app.spec",test_app,
  [{"t2_service",[]},
   {"t3_service",[]},
   {"t4_service",[]},
   {"t1_service",
    [board_w1@asus,test_master_service@asus,board_m1@asus]}]}]=FilterConstrains,
    
    % Build start list -> check if there are services that has no node availiable
[{error,"glurkSpec",glurk,[{g1,[]}]},
 {ok,"test_app_2.spec",test_app_2,
  [{"t10_service",[board_w1@asus,board_m1@asus]}]},
 {error,"test_app.spec",test_app,
  [{"t2_service",[]},
   {"t3_service",[]},
   {"t4_service",[]},
   {"t1_service", 
    [board_w1@asus,test_master_service@asus,
     board_m1@asus]}]}]=[{master:check_start_list(ServiceList,ok),AppSpec,App,ServiceList}||{AppSpec,App,ServiceList}<-[{"glurkSpec",glurk,[{g1,[]}]}|FilterConstrains]],
    %% if Nodes =[] 
    

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
  
