%%% -------------------------------------------------------------------
%%% Author  : uabjle
%%% Description :
%%% dfs:scan(RootDir,Module) -> [Acc]
%%% Excutes a depth first search from RootDir and actions on files or
%%% directories are defined by Module. Actions on regular files is
%%% Module:regular and on directories Module:dir
%%% Result is in a List and Module defines the elements in the list
%%% Created : 10 dec 2012
%%% -------------------------------------------------------------------
-module(dfs).


%% --------------------------------------------------------------------
%% Include files
%% --------------------------------------------------------------------

-include_lib("kernel/include/file.hrl").
%% --------------------------------------------------------------------
%% External exports
-export([search/2]).

%% ====================================================================
%% External functions
%% ====================================================================

search(RootDir,Module)->
    Reply=search(RootDir,Module,[]),
    Reply.
    
%% ====================================================================
%% External functions
%% ====================================================================

search(Path,Module,Acc)->
    case filelib:is_dir(Path) of
	true ->
	    case file:list_dir(Path)of
		{ok,Path_dir_list} ->
		    {ok,Acc1} = search(Path_dir_list,Path,Module,Acc),
		    Result={ok,Acc1};
		{error,Error} ->
		    Result={error_1,Error,?MODULE,?LINE},
		    io:format("Error - Root is not a directory ~p~n",[Path])
	    end;
	false ->
	    Result = {error,is_not_a_directory,?MODULE,?LINE}
	   % io:format("Error - Root is not a directory ~p~n",[Path])
    end,
    Result.

%%
%% Local Functions
%%
		
search([],_Path,_Module,Acc) ->
      {ok,Acc};
	
search(Dir_list,Path,Module,Acc) ->
    [Next_node|T] = Dir_list,
    Next_Fullname = filename:join(Path,Next_node),
    case file_type(Next_Fullname) of
	regular ->
	    {ok,Acc1} = Module:regular(Next_Fullname,Acc);
	directory ->
	    case file:list_dir(Next_Fullname) of
		{ok,Next_node_Dir_list} ->
		    {ok,Acc2} = Module:dir(Next_Fullname,Acc),
		    {ok,Acc1} = search(Next_node_Dir_list,Next_Fullname,Module,Acc);
		{error, Reason} ->          %% troligen en fil som det inte går att accessa ex H directory
%		    io:format("Error in search ~p~n",[Reason]),
%		    io:format("Error in dir/file ~p~n",[file:list_dir(Next_Fullname)]),
		    {ok,Acc1}= search(T,Path,Module,Acc)
	    end;
	X ->
	    io:format("Error ~p~n",[{?MODULE,?LINE,X}]),
	    {ok,Acc1}= search(T,Path,Module,Acc)
    end,
    search(T,Path,Module,Acc1).


%%******************************************************************
% 
%%********************************************************************

file_type(File) ->
    case file:read_file_info(File) of
	{ok, Facts} ->
	    case Facts#file_info.type of
		regular   -> regular;
		directory -> directory;
		X         -> {error,X}
	    end;
	Y ->
	    {error,Y}
    end.
