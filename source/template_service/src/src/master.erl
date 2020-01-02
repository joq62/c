%%% -------------------------------------------------------------------
%%% Author  : uabjle
%%% Description : dbase using dets 
%%%
%%% Created : 10 dec 2012
%%% -------------------------------------------------------------------
-module(master). 
 
%%

%% --------------------------------------------------------------------
%% Data structures  
%% --------------------------------------------------------------------


%% --------------------------------------------------------------------
%% Include files
%% --------------------------------------------------------------------

%% --------------------------------------------------------------------
-define(OS_CMD_1000,1000).
-define(START_POD_INTERVAL,50).
-define(START_POD_TRIES,50).
-define(STOP_POD_INTERVAL,50).
-define(STOP_POD_TRIES,50).

-define(GITHUB,"/home/pi/erlang/erlang_embedded_system_tcp/github").
-define(UPDATE_SERVICE(Service,ServiceInfoRecord),controller_lib:update({service,Service},ServiceInfoRecord)).




%% intermodule 
-export([wanted_apps/1,wanted_apps_list/1
	 ]).

-export([start_app/2,
	 get_start_list/2,
	 %orchistrate/2,
	 get_nodes/0,
	 create_pod/2, delete_pod/2,get_pods/0,
	 create_container/3,delete_container/3
	]).
%% External exports

-compile(export_all).
%% ====================================================================
%% External functions
%% ===================================================================
wanted_apps({Type,Location})->
    List=wanted_apps_list({Type,Location}),    
    [proplists:get_value(specification,Info)||Info<-List].

wanted_apps_list({Type,Location})->
    WantedApps=case Type of 
		   dir->
		       case file:list_dir(Location) of
			   {ok,Files}->
			       L=[file:consult(filename:join(Location,File))||File<-Files,
							      ".spec"==filename:extension(File)],
			       [Info||{ok,Info}<-L];
			   Err->
			       {Err,Type,Location}
		       end;
		   url ->
		       {glurk,?MODULE,?LINE}
	       end,
    WantedApps.
    

%% --------------------------------------------------------------------
%% Function:create_worker_node(Service,MachineNode)
%% Description:
%% Returns:{ok,PidService}|{error,Err}
%% --------------------------------------------------------------------
start_app(AppSpec,ActiveApps)->
    ok.
    
%% --------------------------------------------------------------------
%% Function:create_worker_node(Service,MachineNode)
%% Description:
%% Returns:{ok,PidService}|{error,Err}
%% --------------------------------------------------------------------
get_start_list(WantedApps,StartedApps)->
    ServicesSpecsDependencies=master:get_services_dependendies(StartedApps,WantedApps),
    ActiveMachines=iaas_service:active_machines(),
    A1=[iaas_service:machine_capabilities(list_to_atom(MachineId))||MachineId<-ActiveMachines],
    A11=[L||{ok,L}<-A1],
    MachinesCapa=lists:append(A11),
    Candidates=master:get_candidates(ServicesSpecsDependencies,MachinesCapa),	
    CandidatesConstrains=filter_constrains(Candidates,ServicesSpecsDependencies),
    StartList=[{check_start_list(ServiceList,ok),AppSpec,App,ServiceList}||{AppSpec,App,ServiceList}<-CandidatesConstrains],
    Result=StartList,
    Result.

%% --------------------------------------------------------------------
%% Function:create_worker_node(Service,BoardNode)
%% Description:
%% Returns:{ok,PidService}|{error,Err}
%% --------------------------------------------------------------------
check_machines()->
    {ok,AllMachineIds}=rpc:call(node(),nodes_config,get_all_nodes,[],5000),
    PingResult=[{net_adm:ping(list_to_atom(MachineId)),MachineId}||MachineId<-AllMachineIds],
    ActiveMachines=[MachineId||{pong,MachineId}<-PingResult],
    InActiveMachines=[MachineId||{pang,MachineId}<-PingResult],
    {ActiveMachines,InActiveMachines}.


%% --------------------------------------------------------------------
%% Function:create_worker_node(Service,MachineNode)
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

%% --------------------------------------------------------------------
%% Function:create_worker_node(Service,BoardNode)
%% Description:
%% Returns:{ok,PidService}|{error,Err}
%% --------------------------------------------------------------------
delete_pod(Node,PodId)->
    % Pod='PodId@Host'
    Result=case rpc:call(Node,inet,gethostname,[],5000) of
	       {ok,Host}->
		   PodStr=PodId++"@"++Host,
		   Pod=list_to_atom(PodStr),
		   rpc:call(Pod,init,stop,[],5000),
		    case check_if_vm_stopped(Pod,?STOP_POD_INTERVAL,?STOP_POD_TRIES,error) of
			error->
			    {error,[couldnt_stop_pod,PodId,?MODULE,?LINE]};
			ok->
			    RmCmd="rm -rf "++PodId,
			    case rpc:call(Node,os,cmd,[RmCmd],5000) of
				[]->
				    {ok,stopped};
				Err ->
				    {error,[unknown_error,Err,?MODULE,?LINE]}
			    end
		    end;
	       {badrpc,Err}->
		   {error,[badrpc,Err,?MODULE,?LINE]};
	       Err ->
		   {error,[unknown_error,Err,?MODULE,?LINE]}
	   end,
    Result.
		       


check_if_vm_stopped(_Vm,_Interval,0,ok)->
    ok;
check_if_vm_stopped(_Vm,_Interval,0,error)->
    error;
check_if_vm_stopped(_Vm,_Interval,_N,ok) ->
    ok;
check_if_vm_stopped(Vm,Interval,N,error) ->
    timer:sleep(Interval),
    case net_adm:ping(Vm) of
	pong->
	    NewResult=error;
	pang->
	    NewResult=ok
    end,
    check_if_vm_stopped(Vm,Interval,N-1,NewResult).


%% --------------------------------------------------------------------
%% Function: 
%% Description:
%% Returns: non
%% --------------------------------------------------------------------
create_pod(Node,PodId)->
    Result= case create_pod_dir(Node,PodId) of
		{ok,PodStr}->
		    case start_pod(Node,PodId,PodStr) of
			{ok,Pod}->
			    {ok,Pod};
			 %   Service="pod_controller",  %glurk 
			 %   case create_container(Pod,PodId,"pod_controller") of
			%	{ok,Service}->
			%	    {ok,Pod};
			%	{error,Err}->
			%	    {error,Err}
			 %   end;
			{error,Err}->
			    {error,Err}
		    end;
		{error,Err}->
		    {error,Err}
	    end,
    Result.

start_pod(Node,PodId,PodStr)->
  %  ErlCmd="erl -pa "++"* "++"-sname "++PodStr++" -detached",
%    ErlCmd="erl -pa "++PodId++"/*/* "++"-sname "++PodStr++" -detached",

     ErlCmd="erl "++"-sname "++PodStr++" -detached",
    Result= case rpc:call(Node,os,cmd,[ErlCmd],5000) of
		[]->
		    case check_if_vm_started(list_to_atom(PodStr),?START_POD_INTERVAL,?START_POD_TRIES,error) of
			error->
			    {error,[couldnt_start_pod,PodId,?MODULE,?LINE]};
			ok->
			    {ok,list_to_atom(PodStr)}
		    end;
	        {badrpc,Err}->
		    {error,[badrpc,Err,?MODULE,?LINE]};
		Err ->
		    {error,[unknown_error,Err,?MODULE,?LINE]}
	    end,
    Result.			
create_pod_dir(Node,PodId)->
    % Pod='PodId@Host'
    Result=case rpc:call(Node,inet,gethostname,[],5000) of
	       {ok,Host}->
		   PodStr=PodId++"@"++Host,
		   %Pod=list_to_atom(PodStr),
		   case rpc:call(Node,filelib,is_dir,[PodId],5000) of
		       true->
			   rpc:call(Node,os,cmd,["rm -rf "++PodId],5000),
			   {error,[pod_already_loaded,PodId,?MODULE,?LINE]};
		       false-> 
			   case rpc:call(Node,file,make_dir,[PodId],5000) of
			       ok->
				   {ok,PodStr};
			       {badrpc,Err}->
				   {error,[badrpc,Err,Node,PodId,?MODULE,?LINE]};
			       Err ->
				   {error,[unknown_error,Err,Node,PodId,?MODULE,?LINE]}
			   end;
		       {badrpc,Err}->
			   {error,[badrpc,Err,Node,PodId,?MODULE,?LINE]};
		       Err ->
			   {error,[unknown_error,Err,Node,PodId,?MODULE,?LINE]}
		   end;
	       {badrpc,Err}->
		   {error,[badrpc,Err,Node,PodId,?MODULE,?LINE]};
	       Err ->
		   {error,[unknown_error,Err,Node,PodId,?MODULE,?LINE]}
	   end,
    Result.

check_if_vm_started(_Vm,_Interval,0,ok)->
    ok;
check_if_vm_started(_Vm,_Interval,0,error)->
    error;
check_if_vm_started(_Vm,_Interval,_N,ok) ->
    ok;
check_if_vm_started(Vm,Interval,N,error) ->
    timer:sleep(Interval),
    case net_adm:ping(Vm) of
	pang->
	    NewResult=error;
	pong ->
	    NewResult=ok
    end,
    check_if_vm_started(Vm,Interval,N-1,NewResult).
%% --------------------------------------------------------------------
%% Function: 
%% Description:
%% Returns: non
%% --------------------------------------------------------------------

get_pods()->
    AllNodes=nodes(),
    Result=get_pods(AllNodes,[]),
    Result.
    
get_pods([],Pods)->	   
    Pods;
get_pods([Node|T],Acc) ->	
    [W|_]=string:tokens(atom_to_list(Node),"_"),
    case W of
	"worker"->
	    NewAcc=Acc;
	"controller"->
	    NewAcc=Acc;
	_ ->
	    NewAcc=[Node|Acc]
    end,
    get_pods(T,NewAcc).

%% --------------------------------------------------------------------
%% Function: 
%% Description:
%% Returns: non
%% --------------------------------------------------------------------

get_nodes()->
    AllNodes=nodes(),
    Result=get_nodes(AllNodes,[]),
    Result.
    
get_nodes([],Nodes)->	   
    Nodes;
get_nodes([Node|T],Acc) ->	
    [W|_]=string:tokens(atom_to_list(Node),"_"),
    case W of
	"worker"->
	    NewAcc=[Node|Acc];
	"controller"->
	    NewAcc=[Node|Acc];
	_ ->
	    NewAcc=Acc
    end,
    get_nodes(T,NewAcc).



%% --------------------------------------------------------------------
%%% Internal functions
%% --------------------------------------------------------------------
%% --------------------------------------------------------------------
%% Function: unload_service(Service,BoardNode)
%% Description:
%% Returns:ok|{error,Err}
%% --------------------------------------------------------------------

%% --------------------------------------------------------------------
%% Function:stop_service_node(Service,WorkerNode)
%% Description:
%% Returns:ok|{error,Err}
%% --------------------------------------------------------------------

%% --------------------------------------------------------------------
%% Function:create_worker_node(Service,BoardNode)
%% Description:
%% Returns:{ok,PidService}|{error,Err}
%% --------------------------------------------------------------------

%% --------------------------------------------------------------------
%% Function:clone_compile(Service,BoardNode)
%% Description:
%% Returns: ok|{erro,compile_info}|{error,nodedown}
%% --------------------------------------------------------------------
delete_container(Pod,PodId,ServiceList)->
    delete_container(Pod,PodId,ServiceList,[]).

delete_container(_Pod,_PodId,[],DeleteResult)->
    DeleteResult;
delete_container(Pod,PodId,[Service|T],Acc)->
    NewAcc=[d_container(Pod,PodId,Service)|Acc],
    delete_container(Pod,PodId,T,NewAcc).    
	

d_container(Pod,PodId,Service)->
    Result=case rpc:call(Pod,application,stop,[list_to_atom(Service)],10000) of
	       ok->
		   PathServiceEbin=filename:join([PodId,Service,"ebin"]),
		   case rpc:call(Pod,code,del_path,[PathServiceEbin]) of
		       true->
			   PathServiceDir=filename:join(PodId,Service),
			   case rpc:call(Pod,os,cmd,["rm -rf "++PathServiceDir]) of
			       []->
				   ok;
			       Err ->
				   {error,[undefined_error,Pod,PodId,Service,Err,?MODULE,?LINE]}
			   end;
		       false->
			   {error,[directory_not_found,Pod,PodId,Service,?MODULE,?LINE]};
		       {error,Err}->
			   {error,[Pod,PodId,Service,Err,?MODULE,?LINE]};
		       {badrpc,Err} ->
			   {error,[badrpc,Pod,PodId,Service,Err,?MODULE,?LINE]};
		       Err ->
			   {error,[undefined_error,Pod,PodId,Service,Err,?MODULE,?LINE]}
		   end;
	       {error,{not_started,Err}}->
		   {error,[eexists,Pod,PodId,Service,Err,?MODULE,?LINE]};
	       {badrpc,Err} ->
		   {error,[badrpc,Pod,PodId,Service,Err,?MODULE,?LINE]};
	       Err ->
		   {error,[undefined_error,Pod,PodId,Service,Err,?MODULE,?LINE]}
	   end,
    Result.

%% --------------------------------------------------------------------
%% Function:clone_compile(Service,BoardNode)
%% Description:
%% Returns: ok|{erro,compile_info}|{error,nodedown}
%%
%% PodId/Service
%%
%%
%% --------------------------------------------------------------------
create_container(Pod,PodId,ServiceList)->
    create_container(Pod,PodId,ServiceList,[]).

create_container(_Pod,_PodId,[],CreateResult)->    
    CreateResult;
create_container(Pod,PodId,[Service|T],Acc)->
    NewAcc=[c_container(Pod,PodId,Service)|Acc],
    create_container(Pod,PodId,T,NewAcc).
    
c_container(Pod,PodId,Service)->
    Result =case is_loaded(Pod,PodId,Service) of
		true->
		    {error,[service_already_loaded,Pod,PodId,Service,?MODULE,?LINE]};
		false ->
		    case clone(Pod,PodId,Service) of
			{error,Err}->
		    {error,Err};
			ok ->
			    case compile(Pod,PodId,Service) of
				{error,Err}->
				    {error,Err};
				ok ->
				    %timer:sleep(10000),
				    case start(Pod,PodId,Service) of
					{error,Err}->
					    {error,Err};
					ok->
					    {ok,Service}
				    end
			    end
		    end
	    end,
    Result.
    

%% --------------------------------------------------------------------
%% Function:clone_compile(Service,BoardNode)
%% Description:
%% Returns: ok|{erro,compile_info}|{error,nodedown}
%% --------------------------------------------------------------------
is_loaded(Pod,PodId,Service)->
    PathToService=filename:join(PodId,Service),
    Result = case rpc:call(Pod,filelib,is_dir,[PathToService],5000) of
		 true->
		     true;
		 false->
		     false;
		 {badrpc,Err} ->
		     {error,[badrpc,Pod,PodId,Service,Err,?MODULE,?LINE]};
		 Err ->
		     {error,[undefined_error,Pod,PodId,Service,Err,?MODULE,?LINE]}
	     end,
    Result.

%% --------------------------------------------------------------------
%% Function:clone_compile(Service,BoardNode)
%% Description:
%% Returns: ok|{erro,compile_info}|{error,nodedown}
%% --------------------------------------------------------------------
clone(Pod,PodId,Service)->
    Path=filename:join(?GITHUB,Service),
    %Needs to be changed when using git cloen 
    % 1. git clone https .....
    % 2. mv -r Service PodID
    
    Result=case rpc:call(Pod,os,cmd,["cp -r "++Path++" "++PodId]) of
	       []->
		   ok;
	       {badrpc,Err} ->
		   {error,[badrpc,Pod,PodId,Service,Err,?MODULE,?LINE]};
	       Err->
		   {error,Err}
	   end,
    Result.

%% --------------------------------------------------------------------
%% Function:clone_compile(Service,BoardNode)
%% Description:
%% Returns: ok|{erro,compile_info}|{error,nodedown}
%% --------------------------------------------------------------------
compile(Pod,PodId,Service)->
    PathSrc=filename:join([PodId,Service,"src"]),
    PathEbin=filename:join([PodId,Service,"ebin"]),
    %Get erl files that shall be compiled
    Result=case rpc:call(Pod,file,list_dir,[PathSrc]) of
	       {ok,Files}->
		   FilesToCompile=[filename:join(PathSrc,File)||File<-Files,filename:extension(File)==".erl"],
		   % clean up ebin dir
		   case rpc:call(Pod,os,cmd,["rm  "++PathEbin++"/*"]) of
		       []->
			   CompileResult=[{rpc:call(Pod,c,c,[ErlFile,[{outdir,PathEbin}]],5000),ErlFile}||ErlFile<-FilesToCompile],
			   case [{R,File}||{R,File}<-CompileResult,error==R] of
			       []->
				   AppFileSrc=filename:join(PathSrc,Service++".app"),
				   AppFileDest=filename:join(PathEbin,Service++".app"),
				   case rpc:call(Pod,os,cmd,["cp "++AppFileSrc++" "++AppFileDest]) of
				       []->
					   ok;
				       {badrpc,Err} ->
					   {error,[badrpc,Pod,PodId,Service,Err,?MODULE,?LINE]};
				       Err ->
					   {error,[undefined_error,Pod,PodId,Service,Err,?MODULE,?LINE]}
				   end;
			       CompilerErrors->
				   {error,[compiler_error,CompilerErrors,?MODULE,?LINE]}
			   end;
		       {badrpc,Err} ->
			   {error,[badrpc,Pod,PodId,Service,Err,?MODULE,?LINE]};
		       Err ->
			   {error,[undefined_error,Pod,PodId,Service,Err,?MODULE,?LINE]}
		   end;
	       {badrpc,Err} ->
		   {error,[badrpc,Pod,PodId,Service,Err,?MODULE,?LINE]};
	       Err ->
		   {error,[undefined_error,Pod,PodId,Service,Err,?MODULE,?LINE]}
	   end,
    Result.

%% --------------------------------------------------------------------
%% Function:clone_compile(Service,BoardNode)
%% Description:
%% Returns: ok|{erro,compile_info}|{error,nodedown}
%% --------------------------------------------------------------------
start(Pod,PodId,Service)->
						% glurk=rpc:call(list_to_atom(PodStr),file,list_dir,[PodId++"/*/* "]),
   % glurk=rpc:call(Pod,file,list_dir,[filename:join([PodId,"*","ebin"])]),
    PathServiceEbin=filename:join([PodId,Service,"ebin"]),
    Result = case rpc:call(Pod,code,add_path,[PathServiceEbin],5000) of
		 true->
		     case rpc:call(Pod,application,start,[list_to_atom(Service)],5000) of
			 ok->
			     ok;
			 {badrpc,Err} ->
			     {error,[badrpc,Pod,PodId,Service,Err,?MODULE,?LINE]};
			 Err->
			     {error,[undefined_error,Pod,PodId,Service,Err,?MODULE,?LINE]}
		     end;
		 {badrpc,Err} ->
		     {error,[badrpc,Pod,PodId,Service,Err,?MODULE,?LINE]};
		 Err ->
		     {error,[undefined_error,Pod,PodId,Service,Err,?MODULE,?LINE]}
	     end,
    Result.
