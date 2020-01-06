%%% -------------------------------------------------------------------
%%% Author  : uabjle
%%% Description :

%%% -------------------------------------------------------------------
-module(tar_create).


%% --------------------------------------------------------------------
%% Include files
%% --------------------------------------------------------------------
-include_lib("kernel/include/file.hrl").
%% --------------------------------------------------------------------
%% External exports
-export([start/1]).
%-compile(export_all).
%% ====================================================================
%% External functions
%% ====================================================================

%% ====================================================================
%% External functions
%% ===================================================================
start([RootDir,TarDir,Acc])->
    Result=case filelib:is_dir(RootDir) of
	       true ->
		   case file:list_dir(RootDir)of
		       {ok,RootDirList} ->
			   % Creat inital dir and att tot tar dir
			%   create_tar_files(TarDir,RootDir),
			 
			   BaseName=filename:basename(RootDir),
			   io:format("~p~n",[{"BaseName","->",BaseName,?MODULE,?LINE}]),
			   case filelib:is_dir(BaseName) of
			       true->
				   os:cmd("rm -r "++BaseName);
			       false->
				   ok
			   end,
			   ok=file:make_dir(BaseName),
			   {ok,RootFileNames}=file:list_dir(RootDir),
			   Files2Copy=[{FileName,filename:join([RootDir,FileName])}||FileName<-RootFileNames,FileName/=".git"],
			   
			   Files2Tar=[{filename:join([BaseName,FileName]),file:copy(FileName2Copy,filename:join([BaseName,FileName]))}
				      ||{FileName,FileName2Copy}<-Files2Copy],
			   io:format("~p~n",[{"Files2Tar","->",Files2Tar,?MODULE,?LINE}]),
		%	   TarFileName=BaseName++".tar",
		%	   TarCreatResult=erl_tar:create(TarFileName,Files2Tar),
			   
			   

		%	  io:format("~p~n",[{"BaseName","->",BaseName,?MODULE,?LINE}]),
			   RootTarDir=filename:join([TarDir,BaseName]),
		%	   io:format("~p~n",[{"RootTarDir","->",RootTarDir}]),
			 %  ok=file:make_dir(NewTarDir),
		%	   FileNames=[filename:join([RootDir,FileName])||FileName<-RootDirList,FileName/=".git"],
		%	   Acc1=[{NewTarDir,FileNames}|Acc],
			   search([RootDirList,RootDir,RootTarDir,[]]);
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
		
search([[],_Path,_TarDir,Result]) ->
      Result;
	
search([[NextNode|T],Path,TarDir,Acc]) ->
  %  io:format(" START ++++++++++++++++~n"),
  %  io:format("~p~n",[{"NextNode","->",NextNode,?MODULE,?LINE}]),
  %  io:format("~p~n",[{"Path","->",Path,?MODULE,?LINE}]),
  %  io:format("~p~n",[{"TarDir","->",TarDir,?MODULE,?LINE}]),
  %  io:format(" STOP -----~n"),
    NextFullname = filename:join(Path,NextNode),
    case file_type(NextFullname) of
	regular ->
	    %do_someting with files
	  %  io:format("regular  ~p~n",[{"NextFullname",":=> ",NextFullname,?MODULE,?LINE}]), 
	    NewAcc=Acc;
	directory ->
	    ParentDir=filename:basename(Path),
	  %  io:format(" START ++++++++++++++++~n"),
%	    io:format("~p~n",[{"NextNode","->",NextNode,?MODULE,?LINE}]),
%	    io:format("~p~n",[{"ParentDir","->",ParentDir,?MODULE,?LINE}]),
%	    io:format("~p~n",[{"Path","->",Path,?MODULE,?LINE}]),
%	    io:format("~p~n",[{"TarDir","->",TarDir,?MODULE,?LINE}]),
	    case file:list_dir(NextFullname) of
		{ok,NextNodeDirList} ->
		%    io:format(" ~p~n",[{"NextFullname",":=> ",NextFullname,?MODULE,?LINE}]),
		    % 1 dsf down: 
		    % 1.1 Create dir tar dir
		    % 1.2 Create tar file
		    % 1.3 move tar file -> tardir 
		    
		       % 1.1 Create dir tar dir
		    NextTarDir=filename:join([TarDir,NextNode]),
		    case filelib:is_dir(NextTarDir) of
			false->
		%	    io:format("~p~n",[{"NextTarDir","->",NextTarDir}]);
	                   %   ok=file:make_dir(NextTarDir),
			    ok;
			true->
			    ok
		    end,
		    			
		    % 1.2 Create tar file
		    
		    FileNames=[filename:join([NextFullname,FileName])||FileName<-NextNodeDirList,FileName/=".git"],
	%	    io:format("~p~n",[{"FileNames","->",FileNames}]),
		       %Start
		   
		  %  ok=create_tar_files(NextTarDir,Path),		    
		    Acc1=search([NextNodeDirList,NextFullname,NextTarDir,Acc]),
		  
		    NewAcc=[{NextTarDir,glurk}|Acc1],
		    ok;
		{error,_Reason} ->          
		    %% troligen en fil som det inte går att accessa ex H directory
		    %io:format("Error in search ~p~n",[Reason]),
		    %io:format("Error in dir/file ~p~n",[file:list_dir(Next_Fullname)]),
		    NewAcc=search([T,Path,TarDir,Acc])
	    end;
	X ->
	    io:format("Error ~p~n",[{NextFullname,X,?MODULE,?LINE}]),	    
	    NewAcc=search([T,Path,TarDir,Acc])
    end,
    search([T,Path,TarDir,NewAcc]).

create_tar_files(TarDir,SourceDir)->
  %   io:format("~p~n",[{"TarDir","->",TarDir,?MODULE,?LINE}]),
  %   io:format("~p~n",[{"SourceDir","->",SourceDir,?MODULE,?LINE}]),
 
    %{ok,RootDirFiles}=file:list_dir("."),
    %io:format("~p~n",[{".","->",RootDirFiles,?MODULE,?LINE}]),
    
    % Copy Files to Dir to prevent to have full path for tar
    % use temp dir to get right path service->src->files
    % Create temp dir
    ParentDir=filename:basename(SourceDir),
    SubDir=filename:join([TarDir,ParentDir]),
    io:format("~p~n",[{"SubDir","->",SubDir,?MODULE,?LINE}]),
    case filelib:is_dir(SubDir) of 
	false->
	    ok;
	    %ok=file:make_dir(SubDir);
	true->
	    ok
    end,
  %  ok=file:make_dir(filename:join(ParentDir,TarDir)), 
    % Get file names to tar and copy to Parent/Tardir  
   % {ok,Files}=file:list_dir(filename:join([SourceDir,TarDir])),
   % Files2Tar=[{FileName,filename:join([SourceDir,TarDir,FileName])}||FileName<-Files,FileName/=".git"],
   % io:format("~p~n",[{"Files2Tar","->",Files2Tar,?MODULE,?LINE}]),
    
 %   [file:copy(File2Tar,filename:join([ParentDir,TarDir,FileName]))||{FileName,File2Tar}<-Files2Tar],
%    io:format("~p~n",[{filename:join(ParentDir,TarDir),"->",file:list_dir(filename:join(ParentDir,TarDir)),?MODULE,?LINE}]),
    
        % creat new tarfile list based on new dir  and do tar
%    {ok,NewFiles}=file:list_dir(filename:join([ParentDir,TarDir])),
%    NewFiles2Tar=[filename:join([ParentDir,TarDir,NewFile])||NewFile<-NewFiles],
%    TarFileName=TarDir++".tar",
 %   TarResult=erl_tar:create(TarFileName,NewFiles2Tar),
 %   io:format("~p~n",[{"TarResult","->",TarResult,?MODULE,?LINE}]),

    % cp tar files to PArent 
  %  os:cmd("mv "++TarFileName++" "++ParentDir),
    
    %Remove temp dirs 
  %  os:cmd("rm -r "++filename:join([ParentDir,TarDir])),
    ok.


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


