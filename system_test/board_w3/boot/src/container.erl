%%% -------------------------------------------------------------------
%%% Author  : uabjle
%%% Description : dbase using dets 
%%%
%%% Created : 10 dec 2012
%%% -------------------------------------------------------------------
-module(container). 
 
%% --------------------------------------------------------------------
%% Include files
%% --------------------------------------------------------------------
-include_lib("eunit/include/eunit.hrl").

%% --------------------------------------------------------------------
-define(GITHUB,"/home/pi/erlang/a/source").

%% External exports

-export([create/3,delete/3]).


%% ====================================================================
%% External functions
%% ====================================================================
%% --------------------------------------------------------------------
%% Function:init 
%% Description:
%% Returns: non
%% --------------------------------------------------------------------
%% --------------------------------------------------------------------
%% Function:clone_compile(Service,BoardNode)
%% Description:
%% Returns: ok|{erro,compile_info}|{error,nodedown}
%% --------------------------------------------------------------------
delete(Pod,PodId,ServiceList)->
    delete_container(Pod,PodId,ServiceList,[]).

delete_container(_Pod,_PodId,[],DeleteResult)->
    DeleteResult;
delete_container(Pod,PodId,[ServiceId|T],Acc)->
    NewAcc=[d_container(Pod,PodId,ServiceId)|Acc],
    delete_container(Pod,PodId,T,NewAcc).    
	

d_container(Pod,PodId,ServiceId)->
    Result=case rpc:call(Pod,application,stop,[list_to_atom(ServiceId)],10000) of
	       ok->
		   PathServiceEbin=filename:join([PodId,ServiceId,"ebin"]),
		   case rpc:call(Pod,code,del_path,[PathServiceEbin]) of
		       true->
			   PathServiceDir=filename:join(PodId,ServiceId),
			   case rpc:call(Pod,os,cmd,["rm -rf "++PathServiceDir]) of
			       []->
				   ok;
			       Err ->
				   {error,[undefined_error,Pod,PodId,ServiceId,Err,?MODULE,?LINE]}
			   end;
		       false->
			   {error,[directory_not_found,Pod,PodId,ServiceId,?MODULE,?LINE]};
		       {error,Err}->
			   {error,[Pod,PodId,ServiceId,Err,?MODULE,?LINE]};
		       {badrpc,Err} ->
			   {error,[badrpc,Pod,PodId,ServiceId,Err,?MODULE,?LINE]};
		       Err ->
			   {error,[undefined_error,Pod,PodId,ServiceId,Err,?MODULE,?LINE]}
		   end;
	       {error,{not_started,Err}}->
		   {error,[eexists,Pod,PodId,ServiceId,Err,?MODULE,?LINE]};
	       {badrpc,Err} ->
		   {error,[badrpc,Pod,PodId,ServiceId,Err,?MODULE,?LINE]};
	       Err ->
		   {error,[undefined_error,Pod,PodId,ServiceId,Err,?MODULE,?LINE]}
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
create(Pod,PodId,ServiceList)->
    R=create_container(Pod,PodId,ServiceList,[]),
    case [{error,Err}||{error,Err}<-R] of
	[]->
	    ok;
	Error->
	    {error,Error}
    end.

create_container(_Pod,_PodId,[],CreateResult)->    
    CreateResult;
create_container(Pod,PodId,[{ServiceId,EnvList}|T],Acc)->
    NewAcc=[c_container(Pod,PodId,{ServiceId,EnvList})|Acc],
    create_container(Pod,PodId,T,NewAcc).
    
c_container(Pod,PodId,{ServiceId,EnvList})->
    Result =case is_loaded(Pod,PodId,ServiceId) of
		true->
		    {error,[service_already_loaded,Pod,PodId,ServiceId,?MODULE,?LINE]};
		false ->
		    case clone(Pod,PodId,ServiceId) of
			{error,Err}->
		    {error,Err};
			ok ->
			    case compile(Pod,PodId,ServiceId) of
				{error,Err}->
				    {error,Err};
				ok ->
				    %timer:sleep(10000),
				    case start(Pod,PodId,ServiceId,EnvList) of
					{error,Err}->
					    {error,Err};
					ok->
					    {ok,ServiceId}
				    end
			    end
		    end
	    end,
    timer:sleep(2000),
    Result.
    

%% --------------------------------------------------------------------
%% Function:clone_compile(Service,BoardNode)
%% Description:
%% Returns: ok|{erro,compile_info}|{error,nodedown}
%% --------------------------------------------------------------------
is_loaded(Pod,PodId,ServiceId)->
    PathToService=filename:join(PodId,ServiceId),
    Result = case rpc:call(Pod,filelib,is_dir,[PathToService],5000) of
		 true->
		     true;
		 false->
		     false;
		 {badrpc,Err} ->
		     {error,[badrpc,Pod,PodId,ServiceId,Err,?MODULE,?LINE]};
		 Err ->
		     {error,[undefined_error,Pod,PodId,ServiceId,Err,?MODULE,?LINE]}
	     end,
    Result.

%% --------------------------------------------------------------------
%% Function:clone_compile(Service,BoardNode)
%% Description:
%% Returns: ok|{erro,compile_info}|{error,nodedown}
%% --------------------------------------------------------------------
clone(Pod,PodId,ServiceId)->
    %Needs to be changed when using git cloen 
    % 1. git clone https .....
    % 2. mv -r Service PodID
    % local test
    Path=filename:join(?GITHUB,ServiceId),
    Result=case rpc:call(Pod,os,cmd,["cp -r "++Path++" "++PodId]) of
	       []->
		   case rpc:call(Pod,filelib,is_dir,[filename:join(PodId,ServiceId)],5000) of
		       true->
			   ok;
		       false->
			    {error,[enoent,filename:join(PodId,ServiceId),Pod,PodId,ServiceId,?FILE,?LINE]}
		   end;
	       {badrpc,Err} ->
		   {error,[badrpc,Pod,PodId,ServiceId,Err,?MODULE,?LINE]};
	       Err->
%		   timer:sleep(10000),
		   {error,Err}
	   end,
    Result.

%% --------------------------------------------------------------------
%% Function:clone_compile(Service,BoardNode)
%% Description:
%% Returns: ok|{erro,compile_info}|{error,nodedown}
%% --------------------------------------------------------------------
compile(Pod,PodId,ServiceId)->
    PathSrc=filename:join([PodId,ServiceId,"src"]),
    PathEbin=filename:join([PodId,ServiceId,"ebin"]),
    
    %Get erl files that shall be compiled
    Result=case rpc:call(Pod,file,list_dir,[PathSrc]) of
	       {ok,Files}->
		   FilesToCompile=[filename:join(PathSrc,File)||File<-Files,filename:extension(File)==".erl"],
		   % clean up ebin dir
		   case rpc:call(Pod,os,cmd,["rm -rf "++PathEbin++"/*"]) of
		       []->
			   CompileResult=[{rpc:call(Pod,c,c,[ErlFile,[{outdir,PathEbin}]],5000),ErlFile}||ErlFile<-FilesToCompile],
			   case [{R,File}||{R,File}<-CompileResult,error==R] of
			       []->
				   AppFileSrc=filename:join(PathSrc,ServiceId++".app"),
				   AppFileDest=filename:join(PathEbin,ServiceId++".app"),
				   case rpc:call(Pod,os,cmd,["cp "++AppFileSrc++" "++AppFileDest]) of
				       []->
					 %  io:format("~p~n",[{AppFileSrc,AppFileDest,?FILE,?LINE}]),
					   ok;
				       {badrpc,Err} ->
					   {error,[badrpc,Pod,PodId,ServiceId,Err,?MODULE,?LINE]};
				       Err ->
					   {error,[undefined_error,Pod,PodId,ServiceId,Err,?MODULE,?LINE]}
				   end;
			       CompilerErrors->
				   {error,[compiler_error,CompilerErrors,?MODULE,?LINE]}
			   end;
		       {badrpc,Err} ->
			   {error,[badrpc,Pod,PodId,ServiceId,Err,?MODULE,?LINE]};
		       Err ->
			   {error,[undefined_error,Pod,PodId,ServiceId,Err,?MODULE,?LINE]}
		   end;
	       {badrpc,Err} ->
		   {error,[badrpc,Pod,PodId,ServiceId,Err,?MODULE,?LINE]};
	       Err ->
		   {error,[undefined_error,Pod,PodId,ServiceId,Err,?MODULE,?LINE]}
	   end,
    Result.

%% --------------------------------------------------------------------
%% Function:clone_compile(Service,BoardNode)
%% Description:
%% Returns: ok|{erro,compile_info}|{error,nodedown}
%% --------------------------------------------------------------------
start(Pod,PodId,ServiceId,EnvList)->
    PathServiceEbin=filename:join([PodId,ServiceId,"ebin"]),
    Result = case rpc:call(Pod,code,add_path,[PathServiceEbin],5000) of
		 true->
		     Service=list_to_atom(ServiceId),
		     [application:set_env(Service,Key,Value)||{Key,Value}<-EnvList],
		     case rpc:call(Pod,application,start,[Service],5000) of
			 ok->
			     ok;
			 {badrpc,Err} ->
			     {error,[badrpc,Pod,PodId,ServiceId,Err,?MODULE,?LINE]};
			 {error,{already_started,Service}}->
			     ok;  % Needs to be checked 
			 Err->
			     {error,[undefined_error,Pod,PodId,ServiceId,Err,?MODULE,?LINE]}
		     end;
		 {badrpc,Err} ->
		     {error,[badrpc,Pod,PodId,ServiceId,Err,?MODULE,?LINE]};
		 Err ->
		     {error,[undefined_error,Pod,PodId,ServiceId,Err,?MODULE,?LINE]}
	     end,
    Result.
