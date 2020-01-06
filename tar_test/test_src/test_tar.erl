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

%  SourceDir="/home/pi/erlang/tar_test/root",
  %  SourceDir="/home/pi/erlang/c/tar_test/c/source/adder_service",
% SourceDir="/home/pi/erlang/c/tar_test/c/source/", 
  %  _ParentDir="adder_service",
  %  _DestDir="source",
  %  ExtractDir="/home/pi/erlang/c/tar_test/c/tar_test/extract_dir",

start()->
    SourceDir="/home/pi/erlang/c/source/adder_service",
    TarDir=".",
    BaseName=filename:basename(SourceDir),
    CR=create(SourceDir,TarDir),
    io:format(" ~p~n",[{"CR",":=> ",CR,?MODULE,?LINE}]),
      
    
    Destination="service_dir",
    {ok,Cwd}=file:get_cwd(),
    TarFileName=filename:join([Cwd,BaseName++".tar"]),
    {ok,Bytes}=file:read_file(TarFileName),
    ER=extract(Bytes,Destination),
     io:format(" ~p~n",[{"ER",":=> ",ER,?MODULE,?LINE}]),

    
    init:stop().

%% ====================================================================
%% External functions
%% ====================================================================
create(SourceDir,TarDir)->
   io:format("------------ Create tar files  ~n"), 
    % Create tar dirs
   
    % Cleanup 
  %  os:cmd("rm -r "++TarDir++"/*"),
    CreateTarDirResult=lists:reverse(tar_create:start([SourceDir,TarDir,[{[],0}]])),
 %   io:format(" ~p~n",[{"CreateTarDirResult",":=> ",CreateTarDirResult,?MODULE,?LINE}]), 

   
 
    ok.

extract(TarFile,Destination)->
    io:format(" ~p~n",[{"TarFile",":=> ",?MODULE,?LINE}]),
    io:format(" ~p~n",[{"Destination",":=> ",Destination,?MODULE,?LINE}]),
    %Extract
    io:format(">>>>>>>>>>>>>>> Extract tar files  ~n"), 
    case filelib:is_dir(Destination) of
	true->
	    {error,[copy_to_existing_dir,Destination,?MODULE,?LINE]};
	false->
	    ok,
	    file:make_dir(Destination)
    end,  
    ExtractTarDirResult=tar_extract:extract(TarFile,Destination).
 
  %  io:format(" ~p~n",[{"ExtractTarDirResult",":=> ",ExtractTarDirResult,?MODULE,?LINE}]),  ok.

