%%% -------------------------------------------------------------------
%%% Author  : uabjle
%%% Description : dbase using dets 
%%%
%%% Created : 10 dec 2012
%%% -------------------------------------------------------------------
-module(test_tar). 
  
 

%% --------------------------------------------------------------------
%% Include files
%% --------------------------------------------------------------------

%% --------------------------------------------------------------------
% pre defined

%% External exports

 -compile(export_all).
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
start()->
    SourceDir="/home/pi/erlang/tar_test/c/source/adder_service",
    ParentDir="adder_service",
    DestDir="source",
    ExtractDir="extract_dir",

    
    % clean up
    delete_leaf_files(ParentDir,DestDir),
    timer:sleep(200),
    {ok,ParentFiles}=file:list_dir(SourceDir),
    Dirs2Tar=[File||File<-ParentFiles,filelib:is_dir(filename:join([SourceDir,File]))],
    io:format(" ~p~n",[{"Dirs2Tar",":=> ",Dirs2Tar,?MODULE,?LINE}]),  
    TarFiles=[tar_leaf_dir(SourceDir,ParentDir,TarDir,DestDir)||TarDir<-Dirs2Tar],
    io:format(" ~p~n",[{"TarFiles",":=> ",TarFiles,?MODULE,?LINE}]),  

    ExtractResult= extract_services(DestDir,ExtractDir),
    io:format(" ~p~n",[{"ExtractResult",":=> ",ExtractResult,?MODULE,?LINE}]),  
    init:stop().




    
extract_services(SourceDir,ExtractDir)->
    %% Get all Service tar files and extract in Exrtract dir
    {ok,ServiceTarFiles}=file:list_dir(SourceDir),    

    ServiceTar2Read=[{ServiceTarFile,filename:join([SourceDir,ServiceTarFile])}||ServiceTarFile<-ServiceTarFiles,
										  filename:extension(filename:join([SourceDir,ServiceTarFile]))==".tar"],
    FilesToExtract=[{BaseName,file:read_file(FileName)}||{BaseName,FileName}<-ServiceTar2Read],
    ExtractResult=[{BaseName,erl_tar:extract({binary,TarFile},[verbose])}||{BaseName,{ok,TarFile}}<-FilesToExtract].
    

extract_leaf(TarFileName,Bytes)->
    ok=file:write_file(filename:join([".",TarFileName]),Bytes),
    extract_leaf(TarFileName,".").
extract_leaf(TarFileName,Bytes,_ExtractDir)->
    {ok,TarFile}=file:read_file(TarFileName),
    R=erl_tar:extract({binary,Bytes},[verbose]),
    io:format("erl_tar:extract = ~p~n",[{R,?MODULE,?LINE}]).

    

do_leaf(SourceDir,ParentDir,TarDir,DestDir)->
    {TarFileName,DestDir}=tar_leaf_dir(SourceDir,ParentDir,TarDir,DestDir),
    io:format("tar_leaf_dir -> ~p~n",[{TarFileName,DestDir,?MODULE,?LINE}]),
    {ok,Cwd}=file:get_cwd(),
    TarNameFullPath=filename:join([Cwd,DestDir,TarFileName]),
    extract_leaf(TarNameFullPath,glurk),
    init:stop().
			
tar_leaf_dir(SourceDir,ParentDir,TarDir,DestDir)->
 %   io:format("~p~n",[{"TarDir","->",TarDir,?MODULE,?LINE}]),
    %{ok,RootDirFiles}=file:list_dir("."),
    %io:format("~p~n",[{".","->",RootDirFiles,?MODULE,?LINE}]),
    
    % Copy Files to Dir to prevent to have full path for tar
    % use temp dir to get right path service->src->files
    % Create temp dir
    case filelib:is_dir(ParentDir) of 
	false->
	    ok=file:make_dir(ParentDir);
	true->
	    ok
    end,
    ok=file:make_dir(filename:join(ParentDir,TarDir)), 
    % Get file names to tar and copy to Parent/Tardir  
    {ok,Files}=file:list_dir(filename:join([SourceDir,TarDir])),
    Files2Tar=[{FileName,filename:join([SourceDir,TarDir,FileName])}||FileName<-Files,false==filelib:is_dir(filename:join([SourceDir,TarDir,FileName]))],
    %io:format("~p~n",[{"Files2Tar","->",Files2Tar,?MODULE,?LINE}]),
    
    [file:copy(File2Tar,filename:join([ParentDir,TarDir,FileName]))||{FileName,File2Tar}<-Files2Tar],
%    io:format("~p~n",[{filename:join(ParentDir,TarDir),"->",file:list_dir(filename:join(ParentDir,TarDir)),?MODULE,?LINE}]),
    
        % creat new tarfile list based on new dir  and do tar
    {ok,NewFiles}=file:list_dir(filename:join([ParentDir,TarDir])),
    NewFiles2Tar=[filename:join([ParentDir,TarDir,NewFile])||NewFile<-NewFiles],
    TarFileName=TarDir++".tar",
    TarResult=erl_tar:create(TarFileName,NewFiles2Tar),
 %   io:format("~p~n",[{"TarResult","->",TarResult,?MODULE,?LINE}]),

    % cp tar files to PArent 
    os:cmd("mv "++TarFileName++" "++ParentDir),
    
    %Remove temp dirs 
    os:cmd("rm -r "++filename:join([ParentDir,TarDir])),

    % create final tarfile
    {ok,Tarfiles}=file:list_dir(ParentDir),
 %   io:format("~p~n",[{"Tarfiles","->",Tarfiles,?MODULE,?LINE}]),
    FinalTarFiles=[filename:join([ParentDir,FinalTarFile])||FinalTarFile<-Tarfiles,filename:extension(filename:join([ParentDir,FinalTarFile]))==".tar"],
    ParentTarFileName=ParentDir++".tar",
    TarResult=erl_tar:create(ParentTarFileName,FinalTarFiles),
  %  io:format("~p~n",[{"TarResult","->",TarResult,?MODULE,?LINE}]),
 
    os:cmd("mv "++ParentTarFileName++" "++DestDir),
        %Remove temp dirs 
    os:cmd("rm -r "++ParentDir),
    {ParentTarFileName,DestDir}.

delete_leaf_files(ParentDir,DestDir)->
    os:cmd("rm -r "++ParentDir),  
    os:cmd("rm -r "++DestDir++"/*").
