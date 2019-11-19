%%% -------------------------------------------------------------------
%%% Author  : uabjle
%%% Description : dbase using dets 
%%%
%%% Created : 10 dec 2012
%%% -------------------------------------------------------------------
-module(boot_board).

%% --------------------------------------------------------------------
%% Include files
%% --------------------------------------------------------------------

%% --------------------------------------------------------------------
-define(CONFIG_FILE,"node.config").
%% External exports


-export([start/0
	]).


%% ====================================================================
%% External functions
%% ====================================================================

%% --------------------------------------------------------------------
%% Function: 
%% Description:
%% Returns: non
%% --------------------------------------------------------------------
start()->
    {ok,Info}=file:consult(?CONFIG_FILE),
    {ipaddr,{Ip,Port}}=lists:keyfind(ipaddr,1,Info),
    {keep,Files2Keep}=lists:keyfind(keep,1,Info),
    {master,MasterIpArddrList}=lists:keyfind(master,1,Info),
    clean_up(Files2Keep),
    [PodId,_Host]=string:tokens(atom_to_list(node()),"@"),
    file:make_dir(PodId),
    ok=container:create(node(),PodId,[{"lib_service",[]},
				      {"node_controller_service",
				       [{ipaddr,{Ip,Port}},
					{master,MasterIpArddrList}]}
				     ]),

    
    ok.
%% --------------------------------------------------------------------
%% Function: 
%% Description:
%% Returns: non
%% --------------------------------------------------------------------
%filter_events(Key
clean_up(Keep)->
    Result=case file:list_dir(".") of
	       {ok,Files}->
		   FilesToDelete=file_to_delete(Files,Keep,Files),
		   delete_files(FilesToDelete),
		   ok;
	       {error,Err} ->
		   {error,Err}
	   end,
    Result.


file_to_delete([],_Keep,FilesToDelete)->
    FilesToDelete;
file_to_delete(_Files,[],FilesToDelete)->
    FilesToDelete;
file_to_delete([File|T],Keep,Acc)->
   % io:format("~p~n",[{?MODULE,?LINE,File,Keep,Acc}]),
    NewAcc= case lists:member(File,Keep)of 
		true->
		    lists:delete(File,Acc);
		false->
		    Acc
	    end,
    file_to_delete(T,Keep,NewAcc).
    

delete_files([])->
    ok;
delete_files([File|T])->
    io:format("~p~n",[{?MODULE,?LINE,"rm -rf "++File}]),
    os:cmd("rm -rf "++File),
    timer:sleep(100),
    delete_files(T).
