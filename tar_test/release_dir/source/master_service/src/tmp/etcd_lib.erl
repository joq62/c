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
	 all_machines/0,member/1
	]).
-export([create_deployment/7,delete_deployment/2,update_deployment/7,
	 read_deployment/1,read_deployment/2,
	 create_wanted/4,update_wanted/4,
	 delete_wanted/2,read_wanted/1,read_wanted/2,
	 create_catalog/4,update_catalog/4,
	 delete_catalog/2,read_catalog/1,read_catalog/2,
	 create_machine/2,update_machine/2,
	 delete_machine/1,read_machine/1,read_machine/2
	]).


%% ====================================================================
%% External functions
%% ====================================================================
%% --------------------------------------------------------------------
%% Function: 
%% Description:
%% Returns: non
%% --------------------------------------------------------------------
create_machine(Machine,Status)->
    NewMachine={{machine,Machine,Status},Machine,Status},
    ets:insert(?ETS_NAME,NewMachine),
    ok.
update_machine(Machine,NewStatus)->
    Result=case ets:match(?ETS_NAME,{{machine,Machine,'_'},'$1','$2'}) of
	       []->
		   {error,[]};
	       Info-> % It should only be one! 
		   [[OldMachine,OldStatus]|_]=Info,
		   ets:delete_object(?ETS_NAME,{{machine,OldMachine,OldStatus},OldMachine,OldStatus}),
		   ets:insert(?ETS_NAME,{{machine,Machine,NewStatus},Machine,NewStatus})	   
	   end,
    Result.

delete_machine(Machine)->
    Result=case ets:match(?ETS_NAME,{{machine,Machine,'_'},'$1','$2'}) of
	       []->
		   {error,[]};
	       Info-> % It should only be one! 
		   [[OldMachine,OldStatus]|_]=Info,
		   ets:delete_object(?ETS_NAME,{{machine,OldMachine,OldStatus},OldMachine,OldStatus})
	   end,
    Result.

read_machine(all)->
    Result=case  ets:match(?ETS_NAME,{{machine,'_','_'},'$1','$2'}) of
	       []->
		   {error,[no_machine_info,?MODULE,?LINE]};
	       Infos->
		   A=[Info||Info<-Infos],
		   {ok,A}
	   end,
    Result.
read_machine(Type,Key)->
    Infos = case Type of	    
		machine->
		    ets:match(?ETS_NAME,{{machine,Key,'_'},'$1','$2'});
		status->
		    ets:match(?ETS_NAME,{{machine,'_',Key},'$1','$2'});
		_Err->
		    {error,[wrong_type,Type,?MODULE,?LINE]}
	    end,
		    
    Result=case Infos of
	       {error,Err1}->
		   {error,Err1};
	       []->
		   {error,[no_info,?MODULE,?LINE]};
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
create_catalog(AppId,Vsn,Machine,Services)->
    NewCatalog=[{{catalog,AppId,Vsn,Machine,Services},AppId,Vsn,Machine,Services}],
    ets:insert(?ETS_NAME,NewCatalog),
    ok.
update_catalog(AppId,Vsn,Machine,Services)->
    Result=case ets:match(?ETS_NAME,{{catalog,AppId,Vsn,'_','_'},'$1','$2','$3','$4'}) of
	       []->
		   {error,[]};
	       Info-> % It should only be one! 
		   [[OldAppId,OldVsn,OldMachine,OldService]|_]=Info,
		   ets:delete_object(?ETS_NAME,{{catalog,OldAppId,OldVsn,OldMachine,OldService},
						OldAppId,OldVsn,OldMachine,OldService}),
		   ets:insert(?ETS_NAME,{{catalog,AppId,Vsn,Machine,Services},AppId,Vsn,Machine,Services})	   
	   end,
    Result.

delete_catalog(AppId,Vsn)->
    Result=case ets:match(?ETS_NAME,{{catalog,AppId,Vsn,'_','_'},'$1','$2','$3','$4'}) of
	       []->
		   {error,[]};
	       Info-> % It should only be one! 
		   [[OldAppId,OldVsn,OldMachine,OldService]|_]=Info,
		   ets:delete_object(?ETS_NAME,{{catalog,OldAppId,OldVsn,OldMachine,OldService},
						OldAppId,OldVsn,OldMachine,OldService})  
	   end,
    Result.
read_catalog(all)->
    Result=case ets:match(?ETS_NAME,{{catalog,'_','_','_','_'},'$1','$2','$3','$4'}) of
	       []->
		   {error,[no_machine_info,?MODULE,?LINE]};
	       Infos->
		   A=[Info||Info<-Infos],
		   {ok,A}
	   end,
    Result.
read_catalog(Type,Key)->
    Infos = case Type of	    
		appid->
		    ets:match(?ETS_NAME,{{catalog,Key,'_','_','_'},'$1','$2','$3','$4'});
		vsn->
		    ets:match(?ETS_NAME,{{catalog,'_',Key,'_','_'},'$1','$2','$3','$4'});
		machine->
		    ets:match(?ETS_NAME,{{catalog,'_','_',Key,'_'},'$1','$2','$3','$4'});
		services->
		    ets:match(?ETS_NAME,{{catalog,'_','_','_',Key},'$1','$2','$3','$4'});
		_Err->
		    {error,[wrong_type,Type,?MODULE,?LINE]}
	    end,
		    
    Result=case Infos of
	       {error,Err1}->
		   {error,Err1};
	       []->
		   {error,[no_info,?MODULE,?LINE]};
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
create_wanted(AppId,Vsn,Machine,Services)->
    NewWanted={{wanted,AppId,Vsn,Machine,Services},AppId,Vsn,Machine,Services},
    ets:insert(?ETS_NAME,NewWanted),
    ok.
update_wanted(AppId,Vsn,Machine,Services)->
    Result=case ets:match(?ETS_NAME,{{wanted,AppId,Vsn,'_','_'},'$1','$2','$3','$4'}) of
	       []->
		   {error,[]};
	       Info-> % It should only be one! 
		   [[OldAppId,OldVsn,OldMachine,OldService]|_]=Info,
		   ets:delete_object(?ETS_NAME,{{wanted,OldAppId,OldVsn,OldMachine,OldService},
						OldAppId,OldVsn,OldMachine,OldService}),
		   ets:insert(?ETS_NAME,{{wanted,AppId,Vsn,Machine,Services},AppId,Vsn,Machine,Services})	   
	   end,
    Result.
	    
delete_wanted(AppId,Vsn)->
    Result=case ets:match(?ETS_NAME,{{wanted,AppId,Vsn,'_','_'},'$1','$2','$3','$4'}) of
	       []->
		   {error,[]};
	       Info-> % It should only be one! 
		   [[OldAppId,OldVsn,OldMachine,OldService]|_]=Info,
		   ets:delete_object(?ETS_NAME,{{wanted,OldAppId,OldVsn,OldMachine,OldService},
						OldAppId,OldVsn,OldMachine,OldService})		   
	   end,
    Result.

read_wanted(all)->
    Result=case ets:match(?ETS_NAME,{{wanted,'_','_','_','_'},'$1','$2','$3','$4'}) of
	       []->
		   {error,[no_machine_info,?MODULE,?LINE]};
	       Infos->
		   A=[Info||Info<-Infos],
		   {ok,A}
	   end,
    Result.
read_wanted(Type,Key)->
    Infos = case Type of	    
		appid->
		    ets:match(?ETS_NAME,{{wanted,Key,'_','_','_'},'$1','$2','$3','$4'});
		vsn->
		    ets:match(?ETS_NAME,{{wanted,'_',Key,'_','_'},'$1','$2','$3','$4'});
		machine->
		    ets:match(?ETS_NAME,{{wanted,'_','_',Key,'_'},'$1','$2','$3','$4'});
		services->
		    ets:match(?ETS_NAME,{{wanted,'_','_','_',Key},'$1','$2','$3','$4'});
		_Err->
		    {error,[wrong_type,Type,?MODULE,?LINE]}
	    end,
		    
    Result=case Infos of
	       {error,Err1}->
		   {error,Err1};
	       []->
		   {error,[eexists,Type,Key,?MODULE,?LINE]};
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
create_deployment(AppId,Vsn,Machine,Pod,Container,Service,TimeStamp)->
    NewDeployment={{deployment,AppId,Vsn,Machine,Pod,Container,Service,TimeStamp},AppId,Vsn,Machine,Pod,Container,Service,TimeStamp},
    ets:insert(?ETS_NAME,NewDeployment),
    ok.
update_deployment(AppId,Vsn,Machine,Pod,Container,Service,TimeStamp)->
    Result=case ets:match(?ETS_NAME,{{deployment,AppId,Vsn,Machine,Pod,Container,Service,'_'},'$1','$2','$3','$4','$5','$6','$7'}) of
	       []->
		   {error,[]};
	       Info-> % It should only be one! 
		   [[OldAppId,OldVsn,OldMachine,OldPod,OldContainer,OldService,OldTimeStamp]|_]=Info,
		   ets:delete_object(?ETS_NAME,{{deployment,OldAppId,OldVsn,OldMachine,OldPod,OldContainer,OldService,OldTimeStamp},
						OldAppId,OldVsn,OldMachine,OldPod,OldContainer,OldService,OldTimeStamp}),
		   ets:insert(?ETS_NAME,{{deployment,AppId,Vsn,Machine,Pod,Container,Service,TimeStamp},
					 AppId,Vsn,Machine,Pod,Container,Service,TimeStamp})
	   end,
    Result.

delete_deployment(AppId,Vsn)->
    Result=case ets:match(?ETS_NAME,{{deployment,AppId,Vsn,'_','_','_','_','_'},'$1','$2','$3','$4','$5','$6','$7'}) of
	       []->
		   {error,[]};
	       Info-> % It should only be one! 
		   [[OldAppId,OldVsn,OldMachine,OldPod,OldContainer,OldService,OldTimeStamp]|_]=Info,
		   ets:delete_object(?ETS_NAME,{{deployment,OldAppId,OldVsn,OldMachine,OldPod,OldContainer,OldService,OldTimeStamp},
						OldAppId,OldVsn,OldMachine,OldPod,OldContainer,OldService,OldTimeStamp})
	   end,
    Result.

read_deployment(all)->
    Result=case ets:match(?ETS_NAME,{{deployment,'_','_','_','_','_','_','_'},'$1','$2','$3','$4','$5','$6','$7'}) of
	       []->
		   {error,[no_machine_info,?MODULE,?LINE]};
	       Infos->
		   A=[Info||Info<-Infos],
		   {ok,A}
	   end,
    Result.
read_deployment(Type,Key)->
    Infos = case Type of	    
		appid->
		    ets:match(?ETS_NAME,{{deployment,Key,'_','_','_','_','_','_'},'$1','$2','$3','$4','$5','$6','$7'});
		vsn->
		    ets:match(?ETS_NAME,{{deployment,'_',Key,'_','_','_','_','_'},'$1','$2','$3','$4','$5','$6','$7'});
		machine->
		    ets:match(?ETS_NAME,{{deployment,'_','_',Key,'_','_','_','_'},'$1','$2','$3','$4','$5','$6','$7'});
		pod->
		    ets:match(?ETS_NAME,{{deployment,'_','_','_',Key,'_','_','_'},'$1','$2','$3','$4','$5','$6','$7'});
		container->
		    ets:match(?ETS_NAME,{{deployment,'_','_','_','_',Key,'_','_'},'$1','$2','$3','$4','$5','$6','$7'});
		service->
		    ets:match(?ETS_NAME,{{deployment,'_','_','_','_','_',Key,'_'},'$1','$2','$3','$4','$5','$6','$7'});
		timestamp->
		    ets:match(?ETS_NAME,{{deployment,'_','_','_','_','_','_',Key},'$1','$2','$3','$4','$5','$6','$7'});
		_Err->
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
init(_InitialConfiguration)->
    ?ETS_NAME=ets:new(?ETS_NAME, [bag, named_table]),
    ok.

read_all()->
    ets:match(?ETS_NAME,'$1').

machines_to_ets(MachineList)->
    A=[{{machine,Machine},Machine}||Machine<-MachineList],
    ets:insert(?ETS_NAME,A),
    ok.
app_specs_to_ets(dir,Path)->
    {ok,FileNames}=file:list_dir(Path),
    A=[file:consult(filename:join(Path,FileName))||FileName<-FileNames,".spec"==filename:extension(FileName)],
    AppSpecList=[{catalog,proplists:get_value(specification,Info),Info}||{ok,Info}<-A],
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

%% --------------------------------------------------------------------
%% Function: 
%% Description:
%% Returns: non
%% --------------------------------------------------------------------
%filter_events(Key
