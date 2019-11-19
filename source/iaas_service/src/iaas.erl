%%% -------------------------------------------------------------------
%%% Author  : uabjle
%%% Description : dbase using dets 
%%%
%%% Created : 10 dec 2012
%%% -------------------------------------------------------------------
-module(iaas). 
  


%% --------------------------------------------------------------------
%% Include files
%% --------------------------------------------------------------------

%% --------------------------------------------------------------------


%% intermodule 
-export([active_boards/0
	]).
%% External exports

%-compile(export_all).
%% ====================================================================
%% External functions
%% ===================================================================
%% --------------------------------------------------------------------
%% Function:create_worker_node(Service,BoardNode)
%% Description:
%% Returns:{ok,PidService}|{error,Err}
%% --------------------------------------------------------------------
active_boards()->
    {ok,AllBoards}=rpc:call(node(),nodes_config,get_all_nodes,[],5000),
    Nodes=nodes(),
    ActiveBoards=[atom_to_list(Board)||Board<-Nodes,
			 true==lists:member(atom_to_list(Board),AllBoards)],
    NotActiveBoards=[BoardId||BoardId<-AllBoards,
			false==lists:member(list_to_atom(BoardId),Nodes)],
    {{active,ActiveBoards},{inactive,NotActiveBoards}}.


%% --------------------------------------------------------------------
%%% Internal functions
%% --------------------------------------------------------------------
%% --------------------------------------------------------------------
%% Function: unload_service(Service,BoardNode)
%% Description:
%% Returns:ok|{error,Err}
%% --------------------------------------------------------------------

%% --------------------------------------------------------------------
%% Function:stop_service_node(Service,WorkerNode)
%% Description:
%% Returns:ok|{error,Err}
%% --------------------------------------------------------------------


