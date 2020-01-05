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
-module(test_tar).


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
% -compile(export_all).
%% ====================================================================
%% External functions
%% ===================================================================

%PathSource = "/home/pi/erlang/tar_test/c/source"
% service/[src,ebin,test_src,test_ebin]
% _______________c_______________________
%          |                            |
%   ____service1_________         _____service2____
%   |     |     |       |         |     |     |       |
%  src  ebin  test_src test_ebin src  ebin  test_src test_ebin


%PathNotDir = "/home/pi/erlang/tar_test/c/source/adder_service/src"
% Dir="src"
% DestDir "."
%Module:regular(Next_Fullname,Acc)
% Module:dir(Next_Fullname,Acc)

%dir(DirName,Acc)->
%    {ok,Files}=file:list_dir(DirName),
%    io:format("dir = ~p~n",[{DirName,Files,?MODULE,?LINE}]),
%    [{DirName,Files}|Acc].

%[{"/home/pi/erlang/tar_test/root/dir20","/home/pi/erlang/tar_test/root/dir20"},
% {"/home/pi/erlang/tar_test/root","/home/pi/erlang/tar_test/tar_dir"}]

start()->
  %  SourceDir="/home/pi/erlang/c/tar_test/c/source/adder_service",
    SourceDir="/home/pi/erlang/c/tar_test/c/source/adder_service",
    ParentDir="adder_service",
    DestDir="source",
    ExtractDir="extract_dir",


 %   SourceDir="/home/pi/erlang/tar_test/root",
    TarDir="/home/pi/erlang/c/tar_test/tar_dir",
    R=start(SourceDir,TarDir,[]),
    io:format(" ~p~n",[{"R",":=> ",R,?MODULE,?LINE}]), 
    init:stop().
%% ====================================================================
%% External functions
%% ====================================================================

start(RootDir,TarDir,Acc)->
    Result=case filelib:is_dir(RootDir) of
	       true ->
		   case file:list_dir(RootDir)of
		       {ok,RootDirList} ->
			   % Creat inital dir and att tot tar dir
			   BaseName=filename:basename(RootDir),
			   NewTarDir=filename:join([TarDir,BaseName]),
		%	   ok=file:make_dir(NewTarDir),
			   search(RootDirList,RootDir,NewTarDir,Acc);
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
	  %  io:format("regular  ~p~n",[{"NextFullname",":=> ",NextFullname,?MODULE,?LINE}]), 
	    NewTarDir=TarDir,
	    NewAcc=Acc;
	directory ->
	    case file:list_dir(NextFullname) of
		{ok,NextNodeDirList} ->
			  %Start
		    NewTarDir=filename:join([TarDir,NextNode]),
		    io:format(" ~p~n",[{"NewTarDir",":=> ",NewTarDir,?MODULE,?LINE}]), 
	%	    io:format(" ~p~n",[{"NextNode",":=> ",NextNode,?MODULE,?LINE}]), 
		    io:format(" ~p~n",[{"NextFullname",":=> ",NextFullname,?MODULE,?LINE}]), 
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
