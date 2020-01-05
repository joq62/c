%%% -------------------------------------------------------------------
%%% Author  : uabjle
%%% Description :
%%%
%%% Created : 10 dec 2012
%%% -------------------------------------------------------------------
-module(dfs_orginal).


%% --------------------------------------------------------------------
%% Include files
%% --------------------------------------------------------------------

-include_lib("kernel/include/file.hrl").
%% --------------------------------------------------------------------
%% External exports
-export([dfs/2,count/1,print/1]).


%% ====================================================================
%% External functions
%% ====================================================================


%% --------------------------------------------------------------------
%% Function: handle_call/3
%% Description: Handling call messages
%% Returns: {reply, Reply, State}          |
%%          {reply, Reply, State, Timeout} |
%%          {noreply, State}               |
%%          {noreply, State, Timeout}      |
%%          {stop, Reason, Reply, State}   | (terminate/2 is called)
%%          {stop, Reason, State}            (terminate/2 is called)
%% --------------------------------------------------------------------
count(RootDir)->
    {ok,{NumFiles,NumDirs}} = dfs(RootDir,count),
    io:format("Num of dirs= ~p~n",[NumDirs]),
    io:format("Num of files= ~p~n",[NumFiles]),
    ok.
print(RootDir)->
    Reply = dfs(RootDir,print),
    Reply.

dfs(RootDir,Action)->
    Reply=dfs(RootDir,{0,0},Action),
    Reply.
    

dfs(Path,Acc,Action)->
    case filelib:is_dir(Path) of
	true ->
	    case file:list_dir(Path)of
		{ok,Path_dir_list} ->
		    {ok,Acc1} = dfs(Path_dir_list,Path,Acc,Action),
		    Result={ok,Acc1};
		{error,Result} ->
		    io:format("Error - Root is not a directory ~p~n",[Path])
	    end;
	false ->
	    Result = {error},
	    io:format("Error - Root is not a directory ~p~n",[Path])
    end,
    Result.

%%
%% Local Functions
%%
		
dfs([],_Path,Acc,_Action) ->
      {ok,Acc};
	
dfs(Dir_list,Path,Acc,Action) ->
    [Next_node|T] = Dir_list,
    Next_Fullname = filename:join(Path,Next_node),
    case file_type(Next_Fullname) of
	regular ->
	    {ok,Acc1} = actionfiles(Next_Fullname,Acc,Action);
	directory ->
	    case file:list_dir(Next_Fullname) of
		{ok,Next_node_Dir_list} ->
		    {ok,Acc2} = actiondir(Next_Fullname,Acc,Action),
		    {ok,Acc1} = dfs(Next_node_Dir_list,Next_Fullname,Acc2,Action);
		{error, Reason} ->          %% troligen en fil som det inte går att accessa ex H directory
		    io:format("Error in dfs ~p~n",[Reason]),
		    io:format("Error in dir/file ~p~n",[file:list_dir(Next_Fullname)]),
		    {ok,Acc1}= dfs(T,Path,Acc,Action)
	    end;
	X ->
	    io:format("Error in dfs ~p~n",[X]),
	    {ok,Acc1}= dfs(T,Path,Acc,Action)
    end,
    dfs(T,Path,Acc1,Action).


%%********************************************************************
% action on on files and directories in this example  count files and directories
% {NumFiles,NumDirs}
% 

actionfiles(FilePath,Acc,Action) ->
    case Action of
	count->
	    {NumFiles,NumDirs}=Acc,
	    R={ok,{NumFiles+1,NumDirs}};
	print ->
	    io:format("~p~n",[FilePath]),
	    R={ok,Acc};
	files->
	   % return a regular file with full file name
		R={ok,Acc};
	_ ->
	    R={ok,Acc} 
    end,
    R.

actiondir(_DirPath,Acc,Action)->
    case Action of
	count->
	    {NumFiles,NumDirs}=Acc,
	    R={ok,{NumFiles,NumDirs+1}};
	print->
	    R={ok,Acc};
	_ ->
	    R={ok,Acc} 
    end,
    R.

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
