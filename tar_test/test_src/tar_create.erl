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
			   BaseName=filename:basename(RootDir),
			   NewTarDir=filename:join([TarDir,BaseName]),
			   ok=file:make_dir(NewTarDir),
			   search([RootDirList,RootDir,NewTarDir,Acc]);
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
    NextFullname = filename:join(Path,NextNode),
    case file_type(NextFullname) of
	regular ->
	    %do_someting with files
	  %  io:format("regular  ~p~n",[{"NextFullname",":=> ",NextFullname,?MODULE,?LINE}]), 
	    NewAcc=Acc;
	directory ->
	    case file:list_dir(NextFullname) of
		{ok,NextNodeDirList} ->
		%    io:format(" ~p~n",[{"NextFullname",":=> ",NextFullname,?MODULE,?LINE}]),
                 	  
		       %Start		  
		    TarFileName=NextNode++".tar",
		    %Remove ".git"

		    Files2Tar=[FileName||FileName<-NextNodeDirList,FileName/=".git"],
		    TarResult=erl_tar:create(TarFileName,Files2Tar),
		    
		    BaseName=filename:basename(TarDir),
		    NextTarDir=filename:join([TarDir,NextNode]),
	%	    ok=create_tar_files(TarDir,NextFullname),
		    ok=create_tar_files(NextTarDir,NextFullname),		    
		    [{VisitedDirs,NumDirs}]=Acc,
		    Acc1=[{[NextFullname|VisitedDirs],NumDirs+1}],
			   % End 		
    
		    NewAcc=search([NextNodeDirList,NextFullname,NextTarDir,Acc1]); 
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
  %  io:format("~p~n",[{"TarDir","->",TarDir,?MODULE,?LINE}]),
  %  io:format("~p~n",[{"SourceDir","->",SourceDir,?MODULE,?LINE}]),
    %  Step 1
    % Copy Files to Dir to prevent to have full path for tar
    % use temp dir to get right path service->src->files
    % Create temp dir
    TempDir=filename:basename(TarDir),
    io:format("rm - r ~p~n",[{"TempDir","->",TempDir,?MODULE,?LINE}]),
    case filelib:is_dir(TempDir) of 
	false->
	   ok=file:make_dir(TempDir);
	true->
	    ok
    end, 
    % Get file names to tar and copy to Parent/Tardir  
    
   
   % SourceDestFileNames=[{filename:join([NextFullname,FileName]),filename:join([TempDir,FileName]),FileName}||FileName<-FileNames,
%							     filelib:is_regular(filename:join([TempDir,FileName]))],
 %   io:format(" ~p~n",[{"SourceDestFileNames",":=> ",SourceDestFileNames,?MODULE,?LINE}]),    
  %  {ok,FileNames}=file:list_dir(SourceDir),
  %  Files2Tar=[{FileName,filename:join([SourceDir,TarDir,FileName])}||FileName<-FileNames,
%								      filelib:is_regular(filename:join([SourceDir,TarDir,FileName]))],
   % [file:copy(File2Tar,filename:join([TempDir,FileName]))||{FileName,File2Tar}<-Files2Tar],
  %  io:format("~p~n",[{"Files2Tar","->",Files2Tar,?MODULE,?LINE}]),
    
   
%    io:format("~p~n",[{filename:join(ParentDir,TarDir),"->",file:list_dir(filename:join(ParentDir,TarDir)),?MODULE,?LINE}]),
    
        % creat new tarfile list based on new dir  and do tar
  %  {ok,NewFiles}=file:list_dir(filename:join([ParentDir,TarDir])),
  %  NewFiles2Tar=[filename:join([ParentDir,TarDir,NewFile])||NewFile<-NewFiles],
  %  TarFileName=TarDir++".tar",
						% TarResult=erl_tar:create(TarFileName,NewFiles2Tar),
 %   os:cmd("rm -r "++TempDir),
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


