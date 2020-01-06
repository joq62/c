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
-export([active_machines/0
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
active_machines()->
    {ok,AllMachines}=rpc:call(node(),nodes_config,get_all_nodes,[],5000),
    Nodes=nodes(),
    ActiveMachines=[atom_to_list(Machine)||Machine<-Nodes,
			 true==lists:member(atom_to_list(Machine),AllMachines)],
    NotActiveMachines=[MachineId||MachineId<-AllMachines,
			false==lists:member(list_to_atom(MachineId),Nodes)],
    {{active,ActiveMachines},{inactive,NotActiveMachines}}.


%% --------------------------------------------------------------------
%%% Internal functions
%% --------------------------------------------------------------------
%% --------------------------------------------------------------------
%% Function: unload_service(Service,MachineNode)
%% Description:
%% Returns:ok|{error,Err}
%% --------------------------------------------------------------------

%% --------------------------------------------------------------------
%% Function:stop_service_node(Service,WorkerNode)
%% Description:
%% Returns:ok|{error,Err}
%% --------------------------------------------------------------------


