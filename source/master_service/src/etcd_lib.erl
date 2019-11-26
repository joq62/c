%%% -------------------------------------------------------------------
%%% Author  : uabjle
%%% Description : dbase using dets 
%%%
%%% Created : 10 dec 2012
%%% -------------------------------------------------------------------
-module(etcd_lib).
  

%% --------------------------------------------------------------------
%% Data Structures 
%% --------------------------------------------------------------------
%% Application soecification stored in catalogue
%% {ok,[{specification,new_test_app},{type,application},
%%	 {description,"Specification file for application template"},
%%	 {vsn,"1.0.0"},
%%        {services,[{{service,"t1_service"},{dir,path_t1_service}},
%%	             {{service,"t2_service"},{url,url_t2_service}}]}.
%%
%%---
% Definition of machines
%% {machines,["machine_m1@asus","machine_m2@asus","machine_w1@asus","machine_w2@asus","machine_w3@asus"]}.
%
% List of path or urls to application specifications
%{app_specs,[{dir,"/home/pi/erlang/b/catalogue"}]}.
%
% Usecase 1) Started and not started Applications 
%         2) Started and not started Services
%         3) Service discovery get service
%         4) Add or remove an application
%         5) Add or remove services
%         6) Detect if a service has dissappeare or come back 
%
% Deployment 
%      [{app,AppId},{pod,Pod},{container,Cont},{service,Service},{machine,Machine}]
%      PodId="pod_serviceid_systemtime@host"
%      
%
%% --------------------------------------------------------------------
%% Include files
%% --------------------------------------------------------------------

%% --------------------------------------------------------------------
-define(ETS_NAME,etcd_ets).
%% External exports


-export([init/1,
	 read_all/0,
	 read_catalogue/0,read_catalogue/1,
	 all_machines/0,member/1,
	 store_deployment/5,
	 deployment_info/1,deployment_info/2
	]).


%% ====================================================================
%% External functions
%% ====================================================================
%% --------------------------------------------------------------------
%% Function: 
%% Description:
%% Returns: non
%% --------------------------------------------------------------------
store_deployment(AppId,Pod,Container,Service,Machine)->
    NewDeployment=[{{deployment,AppId,Pod,Container,Service,Machine},AppId,Pod,Container,Service,Machine}],
    ets:insert(?ETS_NAME,NewDeployment),
    ok.
delete_deployment(AppId)->
    ok.
deployment_info(all)->
    Result=case ets:match(?ETS_NAME,{{deployment,'_','_','_','_','_'},'$1','$2','$3','$4','$5'}) of
	       []->
		   {error,[no_machine_info,?MODULE,?LINE]};
	       Infos->
		   A=[Info||Info<-Infos],
		   {ok,A}
	   end,
    Result.
deployment_info(Type,Key)->
    Infos = case Type of	    
		appid->
		    ets:match(?ETS_NAME,{{deployment,Key,'_','_','_','_'},'$1','$2','$3','$4','$5'});
		pod->
		    ets:match(?ETS_NAME,{{deployment,'_',Key,'_','_','_'},'$1','$2','$3','$4','$5'});
		container->
		    ets:match(?ETS_NAME,{{deployment,'_','_',Key,'_','_'},'$1','$2','$3','$4','$5'});
		service->
		    ets:match(?ETS_NAME,{{deployment,'_','_','_',Key,'_'},'$1','$2','$3','$4','$5'});
		machine->
		    ets:match(?ETS_NAME,{{deployment,'_','_','_','_',Key},'$1','$2','$3','$4','$5'});
		Err->
		    {error,[wrong_type,Type,?MODULE,?LINE]}
	    end,
		    
    Result=case Infos of
	       {error,Err1}->
		   {error,Err1};
	       []->
		   {error,[no_machine_info,?MODULE,?LINE]};
	       Infos->
		   A=[Info||Info<-Infos],
		   {ok,A}
	   end,
    Result.
%% --------------------------------------------------------------------
%% Function: 
%% Description:
%% Returns: non
%% --------------------------------------------------------------------
init(InitialConfiguration)->
    Result = case file:consult(InitialConfiguration) of
		 {ok,I}->
		     ?ETS_NAME=ets:new(?ETS_NAME, [bag, named_table]),
		     [{Type,Path}]=proplists:get_value(app_specs,I),
		     ok=app_specs_to_ets(Type,Path),
		     MachineList=proplists:get_value(machines,I),
		     ok=machines_to_ets(MachineList),
		     ok;
		 {error,Err}->
		     {error,[badrpc,Err,create_ets_listfile_consult,InitialConfiguration,?MODULE,?LINE]}
	     end,
    Result.


read_all()->
    ets:match(?ETS_NAME,'$1').

machines_to_ets(MachineList)->
    A=[{{machine,Machine},Machine}||Machine<-MachineList],
    ets:insert(?ETS_NAME,A),
    ok.
app_specs_to_ets(dir,Path)->
    {ok,FileNames}=file:list_dir(Path),
    A=[file:consult(filename:join(Path,FileName))||FileName<-FileNames,".spec"==filename:extension(FileName)],
    AppSpecList=[{catalogue,proplists:get_value(specification,Info),Info}||{ok,Info}<-A],
    ets:insert(?ETS_NAME,AppSpecList),
    ok;
app_specs_to_ets(url,Url)->
    Url;
app_specs_to_ets(Undef1,Undef2) ->
    {error,[unmatched_signal,Undef1,Undef2,?MODULE,?LINE]}.

%%-------------------------------------------------------------------------------------
all_machines()->
    Result=case ets:match(?ETS_NAME,{{machine,'$1'},'_'}) of
	       []->
		   {error,[no_machine_info,?MODULE,?LINE]};
	       Infos->
		   A=[Info||[Info]<-Infos],
		   {ok,A}
	   end,
    Result.
member(Machine)->
    Result=case ets:match(?ETS_NAME,{{machine,Machine},'$1'}) of
	       []->
		   false;
	       [[Machine]]->
		   true
	   end,
    Result.

read_catalogue()->
   % Result=case ets:match(?ETS_NAME,{catalogue,'$1','$2'}) of
    Result=case ets:match(?ETS_NAME,{catalogue,'$1','$2'}) of
	       []->
		   {error,[no_app_specs,?MODULE,?LINE]};
	       AppSpecs->
		   A=[{App,Info}||[App,Info]<-AppSpecs],
		   {ok,A}
	   end,
    Result.
read_catalogue(Application)->
    Result=case ets:match(?ETS_NAME,{catalogue,Application,'$1'}) of
	       []->
		   {error,[no_app_specs,?MODULE,?LINE]};
	       AppsInfo->
		   [[Info]]=AppsInfo,
		   {ok,Info}
	   end,
    Result.


    

%% --------------------------------------------------------------------
%% Function: 
%% Description:
%% Returns: non
%% --------------------------------------------------------------------
%filter_events(Key
