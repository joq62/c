-module(rd_service).

-behaviour(gen_server). 

-export([
         start_link/0,stop/0,
         add_target_resource_type/1,
         add_local_resource/2,
         fetch_resources/1,
         trade_resources/0,
	 debug/1,debug/2
        ]).

-export([init/1, handle_call/3, handle_cast/2, handle_info/2,
         terminate/2, code_change/3]).

-define(SERVER, ?MODULE).

-record(state, {}).

%% API

start_link() ->
    gen_server:start_link({local, ?SERVER}, ?MODULE, [], []).
stop() ->
    gen_server:call(?SERVER, {stop}).


add_target_resource_type(Type) ->
    gen_server:cast(?SERVER, {add_target_resource_type, Type}).

add_local_resource(Type, Resource) ->
    gen_server:cast(?SERVER, {add_local_resource, {Type, Resource}}).

fetch_resources(Type) ->
    ets_rd:get_resources(Type).
  %  gen_server:call(?SERVER, {fetch_resources, Type}).

trade_resources() ->
    gen_server:cast(?SERVER, trade_resources).

debug(Type) ->
    gen_server:call(?SERVER, {debug,Type}).
debug(Type,Service) ->
    gen_server:call(?SERVER, {debug,Type,Service}).

%% Callbacks

init([]) ->
    ets_rd:init(),
    {ok, #state{}}.

handle_call({debug,Type,_Service}, _From, State) ->
    Reply=case Type of
	      state->
		  State;
	      local->
		  ets_rd:get_locals();
	      found->
		  ets_rd:get_founds();
	      target->
		  ets_rd:get_targets()    
	  end,
    {reply, Reply, State};

handle_call({debug,Type}, _From, State) ->
    Reply=case Type of
	      state->
		  State;
	      local->
		  ets_rd:get_locals();
	      found->
		   ets_rd:get_founds();
	      target->
		   ets_rd:get_targets();
	      nodes ->
		  ets_rd:get_active_nodes()
	  end,
    
    {reply, Reply, State};

handle_call({fetch_resources, Type}, _From, State) ->
    Reply=ets_rd:get_resources(Type),
    {reply, Reply, State};

handle_call({stop}, _From, State) ->
    {stop, normal, shutdown_ok, State}.

handle_cast({add_target_resource_type, Type}, State) ->
    ets_rd:store_target(Type),
    {noreply, State};
handle_cast({add_local_resource, {Type, Resource}}, State) ->
    ets_rd:store_local({Type, Resource}),

%   ResourceTuples = State#state.local_resource_tuples,
  %  NewResourceTuples = add_resource(Type, Resource, ResourceTuples),
    {noreply, State};
handle_cast(trade_resources, State) ->
    ResourceTuples =ets_rd:get_locals(),
    AllNodes = [node() | nodes()],
    [gen_server:cast({?SERVER, Node},{trade_resources,{node(), ResourceTuples}})||Node<-AllNodes],
   %% Check if nodes are missing
    ActiveNodes=ets_rd:get_active_nodes(),
    LostNodes=[Node||Node<-ActiveNodes,false==lists:member(Node,AllNodes)],
    case LostNodes of
	[]->
	    no_lost_nodes;
	LostNodes-> %% remove all services realted to that node
	        %FoundTuples=ets_rd:get_founds(),
	   % [delete_found(Lost)
	   % Remove Node from active_nodes
	    [ets_rd:delete_active_node(Node)||Node<-LostNodes],
	    % Remove from found
	    remove_found(LostNodes)   
    end,
    
    %%
%    [gen_server:cast({?SERVER, Node},{trade_resources,{node(), ResourceTuples}})||Node<-AllNodes],
    {noreply, State};
handle_cast({trade_resources, {ReplyTo, Remotes}},State) ->
    store_needed_remotes(Remotes),

    case ReplyTo of
        noreply ->
            ok;
        _ ->
	    Locals=ets_rd:get_locals(),
            gen_server:cast({?SERVER, ReplyTo},
                            {trade_resources, {noreply, Locals}})
    end,
    {noreply, State}.

handle_info(ok = _Info, State) ->
    {noreply, State}.

terminate(_Reason, _State) ->
    ok.

code_change(_OldVsn, State, _Extra) ->
    {ok, State}.


%% Utilities
store_needed_remotes([])->
    ok;
store_needed_remotes(Remotes)->
    store_needed_remotes(Remotes,ets_rd:get_targets()).
store_needed_remotes([],_WantedRemotes)->
    ok;
store_needed_remotes([{Service,Resource}|T],WantedRemotes)->
    case lists:member(Service,WantedRemotes) of
	true->
	    ets_rd:store_found({Service,Resource});
	false ->
	    ok
    end,
    store_needed_remotes(T,WantedRemotes).

remove_found([])->
    ok;
remove_found([LostNode|T])->
    Founds=ets_rd:get_found(LostNode),
 %  io:format("~p~n",[{Founds,?MODULE,?LINE}]),
%    [ io:format("~p~n",[{Service,Resource,?MODULE,?LINE}])||{Service,Resource}<-Founds],
    [ets_rd:delete_found({Service,Resource})||{Service,Resource}<-Founds],
    remove_found(T).   
				 
