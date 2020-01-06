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

    io:format("------------ Create tar files  ~n"), 
    % Create tar dirs
    TarDir="/home/pi/erlang/c/tar_test/tar_dir",
    % Cleanup 
    os:cmd("rm -r "++TarDir++"/*"),
    SourceDir="/home/pi/erlang/c/tar_test/c/source/adder_service",
    CreateTarDirResult=lists:reverse(tar_create:start([SourceDir,TarDir,[{[],0}]])),
 %   io:format(" ~p~n",[{"CreateTarDirResult",":=> ",CreateTarDirResult,?MODULE,?LINE}]), 

    %Extract
%    io:format(">>>>>>>>>>>>>>> Extract tar files  ~n"), 
    ExtractDir="/home/pi/erlang/c/tar_test/extract_dir",   
 %   os:cmd("rm -r "++ExtractDir++"/*"),
   % NewTarDir=filename:join([TarDir]),
  %  ExtractTarDirResult=tar_extract:start([TarDir,ExtractDir,[{[],0}]]),
  %  TarFile="/home/pi/erlang/c/tar_test/tar_dir/adder_service.tar",
   % ExtractTarDirResult=tar_extract:file(TarFile,ExtractDir),
    
  %  io:format(" ~p~n",[{"ExtractTarDirResult",":=> ",ExtractTarDirResult,?MODULE,?LINE}]), 

    init:stop().

%% ====================================================================
%% External functions
%% ====================================================================


