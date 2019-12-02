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
create(Pod,PodId,ServiceList)->
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
    %Needs to be changed when using git cloen 
    % 1. git clone https .....
    % 2. mv -r Service PodID
    % local test
    Path=filename:join(?GITHUB,Service),
    Result=case rpc:call(Pod,os,cmd,["cp -r "++Path++" "++PodId]) of
	       []->
		   ok;
	       {badrpc,Err} ->
		   {error,[badrpc,Pod,PodId,Service,Err,?MODULE,?LINE]};
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
compile(Pod,PodId,Service)->
    PathSrc=filename:join([PodId,Service,"src"]),
    PathEbin=filename:join([PodId,Service,"ebin"]),
    
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
