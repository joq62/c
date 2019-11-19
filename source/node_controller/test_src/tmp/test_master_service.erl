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
-define(W1,'worker_1@asus').
-define(W2,'worker_2@asus').
-define(TEST_APP_SPEC,"test_app.spec").
-define(TEST_2_APP_SPEC,"test_2_app.spec").
-define(LIB_SERVICE_SPEC,"lib_service.spec").
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
     {ok,_Pid}=master_service:start(),
    ok.

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
    ServicesSpecsDependencies=get_services_dependendies(ActiveApps,WantedApps),
    [{"test_app.spec",1,[],
      [{"t1_service",[]},
       {"t4_service",[capa1]},
       {"t3_service",[capa2]},
       {"t2_service",[capa2,capa1]}]},
     {"test_app_2.spec",1,
      [board_w1@asus,board_m1@asus],
      [{"t10_service",[]}]}]= ServicesSpecsDependencies,
    
    %check if there are needs forspecific capabilities
    
    %%% Get availible nodes and allocate 
    %%% 
    ANodes=[{'board_m1@asus',[capa1]},{node(),[]},{'board_w1@asus',[capa1,capa2]}],
    Candidates=get_candidates(ServicesSpecsDependencies,ANodes),			 
   [{"test_app.spec",test_app,
            [{"t1_service",
              [board_w1@asus,test_master_service@asus,board_m1@asus]},
             {"t4_service",[board_m1@asus,board_w1@asus]},
             {"t3_service",[board_w1@asus]},
             {"t2_service",[board_w1@asus]}]},
    {"test_app_2.spec",test_app_2,
     [{"t10_service",
       [board_w1@asus,test_master_service@asus,board_m1@asus]}]}
   ]=Candidates,
    
%%% Check node contstrains and Choose nodes and buld start list
    FilterConstrains=filter_constrains(Candidates,ServicesSpecsDependencies),
    [{"test_app_2.spec",test_app_2,
      [{"t10_service",[board_w1@asus,board_m1@asus]}]
     },
     {"test_app.spec",test_app,
      [{"t2_service",[board_w1@asus]},
       {"t3_service",[board_w1@asus]},
       {"t4_service",[board_m1@asus,board_w1@asus]},
       {"t1_service",[board_w1@asus,test_master_service@asus,board_m1@asus]}
      ]
     }
    ]=FilterConstrains,
    
    % Build start list -> check if there are services that has no node availiable
    [{error,"glurkSpec",glurk,[{g1,[]}]},
     {ok,"test_app_2.spec",test_app_2,
      [{"t10_service",[board_w1@asus,board_m1@asus]}]},
     {ok,"test_app.spec",test_app,
      [{"t2_service",[board_w1@asus]},
       {"t3_service",[board_w1@asus]},
       {"t4_service",[board_m1@asus,board_w1@asus]},
       {"t1_service",[board_w1@asus,test_master_service@asus,board_m1@asus]}]}
    ]=[{check_start_list(ServiceList,ok),AppSpec,App,ServiceList}||{AppSpec,App,ServiceList}<-[{"glurkSpec",glurk,[{g1,[]}]}|FilterConstrains]],
    %% if Nodes =[] 
    

    ok.


			






    

stop_test()->
    master_service:stop(),
    do_kill().
do_kill()->
    init:stop().

%% --------------------------------------------------------------------
%% Function:create_worker_node(Service,BoardNode)
%% Description:
%% Returns:{ok,PidService}|{error,Err}
%% --------------------------------------------------------------------
check_start_list([],R)->
    R;
check_start_list([{_ServiceId,[]}|_],_)->
    check_start_list([],error);
check_start_list([{_ServiceId,_L}|T],_) ->
     check_start_list(T,ok).


filter_constrains(Candidates,ServicesSpecsDependencies)->
    filter_constrains(Candidates,ServicesSpecsDependencies,[]).

filter_constrains([],_ServicesSpecsDependencies,FilterConstrains)->
    FilterConstrains;
filter_constrains([{AppSpec,App,CandidateList}|T],ServicesSpecsDependencies,Acc) ->
   % glurk=lists:keyfind(AppSpec,1,ServicesSpecsDependencies),
    NewServiceList=case lists:keyfind(AppSpec,1,ServicesSpecsDependencies) of
		       false->
			   {error,[no_entry,AppSpec,?MODULE,?LINE]};
		       {AppSpec,_Num,ConstrainList,_NeededCapa}->
			   do_filter(CandidateList,ConstrainList,[]);
		       Err ->
			   {error,[undefined_error,Err,?MODULE,?LINE]}
		   end,
    NewAcc=[{AppSpec,App,NewServiceList}|Acc],
    filter_constrains(T,ServicesSpecsDependencies,NewAcc).
			   

do_filter([],_,Constrains)->
    Constrains;
do_filter([{ServiceId,BoardList}|T],[],Acc) -> % No constrains
    NewAcc=[{ServiceId,BoardList}|Acc],
    do_filter(T,[],NewAcc);
do_filter([{ServiceId,BoardList}|T],Constrain,Acc) ->
    Filtered=[Board||Board<-BoardList,
		     lists:member(Board,Constrain)],
 %   Filtered=[{lists:member(Board,Constrain),Board}||Board<-BoardList],
    NewAcc=[{ServiceId,Filtered}|Acc],
  %  glurk={ServiceId,BoardList,"+++",T},
    do_filter(T,Constrain,NewAcc).
		   
	    



%% --------------------------------------------------------------------
%% Function:create_worker_node(Service,BoardNode)
%% Description:
%% Returns:{ok,PidService}|{error,Err}
%% --------------------------------------------------------------------
get_candidates(ServicesSpecsDependencies,ANodes)->
    candidate_node(ServicesSpecsDependencies,ANodes,[]).

candidate_node([],_,Candidates)->
    filter_candidates(Candidates,[]);
candidate_node([{AppSpec,_Num,_WantedNodes,ServiceList}|T],ANodes,Acc) ->
    Cap=capabilities(ServiceList,ANodes,[]),
    NewAcc=[{AppSpec,spec:read(specification,AppSpec),Cap}|Acc], %lists:append(Cap,Acc),
    candidate_node(T,ANodes,NewAcc).


filter_candidates([],Filter)->
    Filter;
filter_candidates([{AppSpec,App,ServiceList}|T],Acc) ->
    NewAcc=[{AppSpec,App,filter_candidates_1(ServiceList,[])}|Acc],
    filter_candidates(T,NewAcc).
    
filter_candidates_1([],Candidates) ->
    Candidates;
filter_candidates_1([{ServiceId,[]}|T],Acc) ->
    NewAcc=[{ServiceId,[]}|Acc],
    filter_candidates_1(T,NewAcc);
filter_candidates_1([{ServiceId,[L1|LT]}|T],Acc) ->
    NewAcc=[{ServiceId,check_in_all(L1,LT,[])}|Acc],
    filter_candidates_1(T,NewAcc).

check_in_all([],_ListBoards,InAll)->
    InAll;
check_in_all([Board|T],ListBoards,Acc)->
    Test=[{false,Board}||SubList<-ListBoards,false==lists:member(Board,SubList)],
    NewAcc=case Test of
	       []-> %present in all 
		   [Board|Acc];
	       _NotInAll->
		   Acc
	   end,
    check_in_all(T,ListBoards,NewAcc).
    
capabilities([],_,Capabilities)->
    Capabilities;
capabilities([{ServiceId,[]}|T],ANodes,Acc)->
    NewAcc=[{ServiceId,[[Board||{Board,_}<-ANodes]]}|Acc],
    capabilities(T,ANodes,NewAcc);
capabilities([{ServiceId,CapList}|T],ANodes,Acc) ->
    C1=[cap_member(WCap,ANodes,[])||WCap<-CapList],
    NewAcc=[{ServiceId,C1}|Acc],
    capabilities(T,ANodes,NewAcc).

cap_member(_,[],Member)->
    Member;
cap_member(WCap,[{Node,CapList}|T],Acc) ->
    NewAcc=case lists:member(WCap,CapList) of
	       false->
		   Acc;
	       true->
		   [Node|Acc]
	   end,
    cap_member(WCap,T,NewAcc).
	
%% --------------------------------------------------------------------
%% Function:create_worker_node(Service,BoardNode)
%% Description:
%% Returns:{ok,PidService}|{error,Err}
%% --------------------------------------------------------------------
get_services_dependendies(ActiveApps,WantedApps)->
    AppsToStart=[AppSpec||AppSpec<-WantedApps,
			  false==lists:keymember(spec:read(specification,AppSpec),
						 1,ActiveApps)],
    %% Get Services, dependencies and needed  capabilities
    %% Get services and their dependencies 
    Specs=[{AppSpec,spec:read(instances,AppSpec),spec:read(localization,AppSpec),
	    spec:read(service_def,AppSpec)}||AppSpec<-AppsToStart],
 %   [{"test_app.spec",1,[],[{"t1_service","t1.spec"}]}]=Specs,
    
    R1=[{AppSpec,Num,Local,check_service_specs(ServiceSpec)}||{AppSpec,Num,Local,ServiceSpec}<-Specs],
    ServicesSpecsDependencies=case [{error,AppSpec,Num,Node,ServiceList}||{AppSpec,Num,Node,{error,ServiceList}}<-R1] of
				  []->
				      R2=[{AppSpec,Num,Node,ServiceList}||{AppSpec,Num,Node,{ok,ServiceList}}<-R1],
				      R2;
				  Error->
				      {error,Error}
			      end,
    ServicesSpecsDependencies.


check_service_specs([])->
    {ok,[]};
check_service_specs(ServiceSpec)->
    check_service_specs(ServiceSpec,[],started).

check_service_specs(_,ServicesSpecsDependencies,error)->
    {error,ServicesSpecsDependencies};
check_service_specs([],ServicesSpecsDependencies,ok)->
    {ok,ServicesSpecsDependencies};
check_service_specs([{ServiceId,ServiceSpec}|T],Acc,_)->
    %download the servicespec from catalog 
    % [download(ServiceId,ServiceSpec)||{ServiceId,ServiceSpec}<-ServiceSpecList
    NewAcc=case spec:read(dependencies,ServiceSpec) of
	       []->
		   L=[{ServiceId,spec:read(needed_capabilities,ServiceSpec)}],
		   lists:append(L,Acc);
	       DepList->
		   L=[{ServiceId,spec:read(needed_capabilities,ServiceSpec)}],
		   {ok,List2}=check_service_specs(DepList),
		   lists:append([L,List2,Acc])
	   end,
    check_service_specs(T,NewAcc,ok).
