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
-export([start/3]).

%% ====================================================================
%% External functions
%% ====================================================================
    
%% ====================================================================
%% External functions
%% ====================================================================

start(RootDir,TarDir,Acc)->
    Result=case filelib:is_dir(RootDir) of
	       true ->
		   case file:list_dir(RootDir)of
		       {ok,RootDirList} ->
			   search(RootDirList,RootDir,TarDir,Acc);
		       {error,Error} ->
			   io:format("Error -  is not a directory ~p~n",[RootDir]),
			   {error,[unmatched,Error,RootDir,?MODULE,?LINE]}		  
		   end;
	       false ->
		   {error,[is_not_a_directory,RootDir,?MODULE,?LINE]}
	   % io:format("Error - Root is not a directory ~p~n",[Path])
    end,
    Result.

%%
%% Local Functions
%%
		
search([],_Path,_TarDir,Result) ->
      Result;
	
search([NextNode|T],Path,TarDir,Acc) ->
    NextFullname = filename:join(Path,NextNode),
    case file_type(NextFullname) of
	regular ->
	    %do_someting with files
	    io:format("regular  ~p~n",[{"NextFullname",":=> ",NextFullname,?MODULE,?LINE}]), 
	    NewTarDir=TarDir,
	    NewAcc=Acc;
	directory ->
	    case file:list_dir(NextFullname) of
		{ok,NextNodeDirList} ->
			  %Start
		    NewTarDir=filename:join([TarDir,NextNode]),
		    io:format(" ~p~n",[{"NewTarDir",":=> ",NewTarDir,?MODULE,?LINE}]), 
			   % End 
		    NewAcc=search(NextNodeDirList,NextFullname,NewTarDir,Acc); 
		{error,_Reason} ->          
		    %% troligen en fil som det inte går att accessa ex H directory
		    %io:format("Error in search ~p~n",[Reason]),
		    %io:format("Error in dir/file ~p~n",[file:list_dir(Next_Fullname)]),
		    NewTarDir=TarDir,
		    NewAcc=search(T,Path,TarDir,Acc)
	    end;
	X ->
	    io:format("Error ~p~n",[{NextFullname,X,?MODULE,?LINE}]),
	    NewTarDir=TarDir,	    
	    NewAcc=search(T,Path,TarDir,Acc)
    end,
    search(T,Path,NewTarDir,NewAcc).


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
