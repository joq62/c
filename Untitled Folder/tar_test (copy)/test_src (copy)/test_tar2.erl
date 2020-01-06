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
-module(test_tar2).


%% --------------------------------------------------------------------
%% Include files
%% --------------------------------------------------------------------

-include_lib("kernel/include/file.hrl").
%% --------------------------------------------------------------------
%% External exports
-export([start/0]).

%% ====================================================================
%% External functions
%% ====================================================================

   
%% ====================================================================
%% External functions
%% ====================================================================

search(Source,TarDir,Acc)->
    Result=case filelib:is_dir(Path) of
	       true ->
		   case file:list_dir(Path)of
		       {ok,Path_dir_list} ->
			   search(Path_dir_list,Path,Module,AccRegular,AccDir);
		       {error,Error} ->
			   io:format("Error -  is not a directory ~p~n",[Path]),
			   {error,[unmatched,Error,Path,?MODULE,?LINE]}		  
		   end;
	       false ->
		   {error,[is_not_a_directory,Path,?MODULE,?LINE]}
	   % io:format("Error - Root is not a directory ~p~n",[Path])
    end,
    Result.

%%
%% Local Functions
%%
		
search([],_TarDir,Acc) ->
      Acc;
	
search(Source,TarDir,Acc) ->
    [Next_node|T] = Dir_list,
    Next_Fullname = filename:join(Path,Next_node),
    NewAcc=case file_type(Next_Fullname) of
	       regular ->
		   Acc;
	       directory ->
		   case file:list_dir(Next_Fullname) of
		       {ok,Next_node_Dir_list} ->
			   io:format(" ~p~n",[{"Next_Fullname",":=> ",Next_Fullname,?MODULE,?LINE}]), 			   
			 %  TarDirList=[filename:join([TarDir,File])||File<-Next_node_Dir_list,
				%				     filelib:is_dir(filename:join([TarDir,File]))],
			   search(Next_Fullname,); 
		       {error,_Reason} ->          
		    %% troligen en fil som det inte går att accessa ex H directory
		    %io:format("Error in search ~p~n",[Reason]),
		    %io:format("Error in dir/file ~p~n",[file:list_dir(Next_Fullname)]),
		    {NewAccRegular,NewAccDir}=search(T,Path,Module,AccRegular,AccDir)
		   end;
	       X ->
		   io:format("Error ~p~n",[{?MODULE,?LINE,X}]),
		   {NewAccRegular,NewAccDir}=search(T,Path,Module,AccRegular,AccDir)
	   end,
    search(T,NewTarDir,Acc).


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
