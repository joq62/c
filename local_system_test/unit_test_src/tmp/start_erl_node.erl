%%% -------------------------------------------------------------------
%%% Author  : uabjle
%%% Description : dbase using dets 
%%%
%%% Created : 10 dec 2012
%%% -------------------------------------------------------------------
-module(start_erl_node). 
 
%% --------------------------------------------------------------------
%% Include files
%% --------------------------------------------------------------------
-include_lib("eunit/include/eunit.hrl").

%% --------------------------------------------------------------------
-define(ID_NODE1,"node1").
-define(ID_NODE2,"node2").

-define(START_POD_INTERVAL,50).
-define(START_POD_TRIES,50).
%% External exports

-export([start_node/2]).


%% ====================================================================
%% External functions
%% ====================================================================
%% --------------------------------------------------------------------
%% Function:init 
%% Description:
%% Returns: non
%% --------------------------------------------------------------------
start_node(Node,NodeId)->
    create_pod(Node,NodeId).
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
