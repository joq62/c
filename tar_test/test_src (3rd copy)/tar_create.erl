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
    BaseName=filename:basename(RootDir),
    Result=case filelib:is_dir(BaseName) of
	       true->
		   {error,[root_dir_is_in_cwd,RootDir,?MODULE,?LINE]};
	       false->
		   case filelib:is_dir(RootDir) of
		       true ->
			   case file:list_dir(RootDir)of
			       {ok,RootDirList} ->
						% Creat inital dir and att tot tar dir
				   % dfs down: creat dir and copy files 
				   % search in next nod 
				   % creat tar dir and copy it!
				   RootBaseName=filename:basename(RootDir),
				   io:format("~p~n",[{"RootBaseName","->",RootBaseName,?MODULE,?LINE}]),
				   case filelib:is_dir(RootBaseName) of
				       true->
					   ok;
				       false->
					   ok=file:make_dir(RootBaseName)
				   end,
				   {ok,RootFileNames}=file:list_dir(RootDir),
				   Regular2Copy=[{FileName,filename:join([RootDir,FileName])}||FileName<-RootFileNames,
											     filelib:is_regular(FileName)],
				 
				   CopiedFiles=[{filename:join([RootBaseName,FileName]),file:copy(FileName2Copy,filename:join([RootBaseName,FileName]))}
						||{FileName,FileName2Copy}<-Regular2Copy],
				   io:format("~p~n",[{"CopiedFiles","->",CopiedFiles,?MODULE,?LINE}]),
				  % Magic
				   RootTarDir=filename:join([".",RootBaseName]), 
				   io:format("~p~n",[{"RootTarDir","->",RootTarDir,?MODULE,?LINE}]),
				   SearchResult=search([RootDirList,RootDir,RootTarDir,[]]),

				   %creater tar file
				   {ok,FileNames}=file:list_dir(RootBaseName),
				   io:format("~p~n",[{"FileNames","->",FileNames,?MODULE,?LINE}]),
				   Files2Tar=[filename:join([RootBaseName,FileName])||FileName<-FileNames],
				   TarFileName=RootBaseName++".tar",
				   TarCreatResult=erl_tar:create(TarFileName,Files2Tar),
				   [TarCreatResult|SearchResult];
		%	   ,
		%	  
			   
			   

		%	  io:format("~p~n",[{"BaseName","->",BaseName,?MODULE,?LINE}]),
				   
		%	   io:format("~p~n",[{"RootTarDir","->",RootTarDir}]),
			 %  ok=file:make_dir(NewTarDir),
		%	   FileNames=[filename:join([RootDir,FileName])||FileName<-RootDirList,FileName/=".git"],
		%	   Acc1=[{NewTarDir,FileNames}|Acc],
				  
			       {error,Error} ->
				   io:format("Error -  is not a directory ~p~n",[RootDir]),
				   {error,[unmatched,Error,RootDir,?MODULE,?LINE]}		  
			   end;
		       false ->
			   {error,[is_not_a_directory,RootDir,?MODULE,?LINE]}
	   % io:format("Error - Root is not a directory ~p~n",[Path])
		   end
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
		    
		    %RootBaseName=filename:basename(RootDir),
		    
		  %  io:format("~p~n",[{"RootBaseName","->",RootBaseName,?MODULE,?LINE}]),
		    NextTarDir=filename:join([TarDir,NextNode]),
		  %  io:format("~p~n",[{"NextTarDir","->",NextTarDir,?MODULE,?LINE}]),
		    case filelib:is_dir(NextTarDir) of
			true->
			    ok;
			false->
			    ok=file:make_dir(NextTarDir)
		    end,
		    {ok,NextNodesFileNames}=file:list_dir(NextFullname),
	%	    io:format("~p~n",[{"NextNodesFileNames","->",NextNodesFileNames,?MODULE,?LINE}]),
		    Regular2Copy=[{FileName,filename:join([NextFullname,FileName])}||FileName<-NextNodesFileNames,
										filelib:is_regular(filename:join([NextFullname,FileName]))],
	%	    io:format("~p~n",[{"Regular2Copy","->",Regular2Copy,?MODULE,?LINE}]),
		  %  CopiedFiles=[filename:join([NextTarDir,FileName])||{FileName,_}<-Regular2Copy],
		    CopiedFiles=[{filename:join([NextTarDir,FileName]),file:copy(FileName2Copy,filename:join([NextTarDir,FileName]))}
						||{FileName,FileName2Copy}<-Regular2Copy],
	%	    io:format("~p~n",[{"CopiedFiles","->",CopiedFiles,?MODULE,?LINE}]),
		       % Magic
		    SearchResult=search([NextNodeDirList,NextFullname,NextTarDir,[]]),
	%	    io:format("~p~n",[{"SearchResult","->",SearchResult,?MODULE,?LINE}]),

				   %creater tar file
		    {ok,FileNames}=file:list_dir(NextTarDir),
		  %  io:format("~p~n",[{"FileNames","->",FileNames,?MODULE,?LINE}]),
		    Files2Tar=[filename:join([NextTarDir,FileName])||FileName<-FileNames],
	%	    io:format("~p~n",[{"Files2Tar","->",Files2Tar,?MODULE,?LINE}]),
		    TarFileName=NextNode++".tar",
		    io:format("~p~n",[{"TarFileName","->",TarFileName,?MODULE,?LINE}]),
		    TarCreatResult=erl_tar:create(TarFileName,Files2Tar),
		 
		  %  NewAcc=[glurk|SearchResult];
		    NewAcc=[TarCreatResult|SearchResult];
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


