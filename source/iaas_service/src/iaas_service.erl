%%% -------------------------------------------------------------------
%%% Author  : Joq Erlang
%%% Description :iaas
%%% Infrastructure controller
%%% Main is task to keep track of availible nodes. I shall also keep
%%% track on latency
%%% The controller keeps information about availibility  
%%% Input is which nodes that are expected to be presents and what 
%%% characteristics they have
%%% The controller polls each node every minute to check if it's present
%%% An ets table is used to keep information   
%%% Created : 10 dec 2012
%%% -------------------------------------------------------------------
-module(iaas_service). 

-behaviour(gen_server).
%% --------------------------------------------------------------------
%% Include files
%% --------------------------------------------------------------------
-define(NODES_CONFIG,"nodes.config").
-define(JOSCA,"josca").
-define(POLL_INTERVAL,1*1000).

%% --------------------------------------------------------------------
 
%% --------------------------------------------------------------------
%% Key Data structures
%% 
%% --------------------------------------------------------------------
-record(state,{active,inactive}).


	  
%% --------------------------------------------------------------------

%% ====================================================================
%% External functions
%% ====================================================================


%% user interface
-export([
	 
	]).

%% intermodule 
-export([get_nodes/0,get_pods/0,
	 ip_addr/1,ip_addr/2,
	 zone/0,zone/1,capability/1,
	 get_all_nodes/0,
	 active_boards/0,inactive_boards/0,
	 check_boards/1
%	 h_beat/1
	]).

-export([start/0,
	 stop/0
	 ]).
%% internal 
%% gen_server callbacks
-export([init/1, handle_call/3,handle_cast/2, handle_info/2, terminate/2, code_change/3]).


%% ====================================================================
%% External functions
%% ====================================================================

%% Asynchrounus Signals

%% Gen server function

start()-> gen_server:start_link({local, ?MODULE}, ?MODULE, [], []).
stop()-> gen_server:call(?MODULE, {stop},infinity).


%%----------------------------------------------------------------------
active_boards()->
    gen_server:call(?MODULE,{active_boards},infinity).
inactive_boards()->
    gen_server:call(?MODULE,{inactive_boards},infinity).


get_all_nodes()->
    gen_server:call(?MODULE,{get_all_nodes},infinity).

zone()->
    gen_server:call(?MODULE,{zone},infinity).

zone(Node)->
    gen_server:call(?MODULE,{zone,Node},infinity).

capability(Capability)->
    gen_server:call(?MODULE,{capability,Capability},infinity).

ip_addr(BoardId)->
    gen_server:call(?MODULE,{ip_addr,BoardId},infinity).

ip_addr(IpAddr,Port)->
    gen_server:call(?MODULE,{ip_addr,IpAddr,Port},infinity).

%%___________________________________________________________________
get_nodes()->
    gen_server:call(?MODULE, {get_nodes},infinity).

get_pods()->
    gen_server:call(?MODULE, {get_pods},infinity).

%%-----------------------------------------------------------------------
check_boards(Interval)->
    gen_server:cast(?MODULE,{check_boards,Interval}).

%% ====================================================================
%% Server functions
%% ====================================================================

%% --------------------------------------------------------------------
%% Function: init/1
%% Description: Initiates the server
%% Returns: {ok, State}          |
%%          {ok, State, Timeout} |
%%          ignore               |
%%          {stop, Reason}
%
%% --------------------------------------------------------------------
init([]) ->
    % Initiate ets table based on configurration file
    true=nodes_config:init(?NODES_CONFIG),
    % Connect to all nodes - ensure that they are in dist erlang
    
    spawn(fun()->do_poll(?POLL_INTERVAL) end),
  %  {{active,ActiveBoards},{inactive,InActive}}=iaas:active_boards(),
    io:format("Dbg ~p~n",[{?MODULE, application_started}]),
 %   {ok, #state{active=ActiveBoards,inactive=InActive}}.
    {ok, #state{}}.
    
%% --------------------------------------------------------------------
%% Function: handle_call/3
%% Description: Handling call messages
%% Returns: {reply, Reply, State}          |
%%          {reply, Reply, State, Timeout} |
%%          {noreply, State}               |
%%          {noreply, State, Timeout}      |
%%          {stop, Reason, Reply, State}   | (terminate/2 is called)
%%          {stop, Reason, State}            (aterminate/2 is called)
%% --------------------------------------------------------------------


%---------------------------------------------------------------

handle_call({active_boards}, _From, State) ->
    Reply=State#state.active,
    {reply, Reply, State};

handle_call({inactive_boards}, _From, State) ->
    Reply=State#state.inactive,
    {reply, Reply, State};

handle_call({get_all_nodes}, _From, State) ->
    Reply=rpc:call(node(),nodes_config,get_all_nodes,[],5000), 
    {reply, Reply, State};

handle_call({ip_addr,BoardId}, _From, State) ->
    Reply=rpc:call(node(),nodes_config,ip_addr,[BoardId],5000), 
    {reply, Reply, State};

handle_call({ip_addr,IpAddr,Port}, _From, State) ->
    Reply=rpc:call(node(),nodes_config,ip_addr,[IpAddr,Port],5000), 
    {reply, Reply, State};

handle_call({zone}, _From, State) ->
    Reply=rpc:call(node(),nodes_config,zone,[],5000), 
    {reply, Reply, State};

handle_call({zone,Node}, _From, State) ->
    Reply=rpc:call(node(),nodes_config,zone,[atom_to_list(Node)],5000),
    {reply, Reply, State};

handle_call({capability,Capability}, _From, State) ->
    Reply=case rpc:call(node(),nodes_config,capability,[Capability],5000) of
	      []->
		  {ok,[]};
	      {ok,Capabilities}->
		  {ok,Capabilities};
	      Err->
		  {error,[Err,?MODULE,?LINE]}
	  end,
    {reply, Reply, State};

%----------------------------------------------------------------------
handle_call({get_nodes}, _From, State) ->
    Reply=rpc:call(node(),controller,get_nodes,[],5000),
    {reply, Reply, State};

handle_call({get_pods}, _From, State) ->
    Reply=rpc:call(node(),controller,get_pods,[],5000),
    {reply, Reply, State};

handle_call({create_pod,Node,PodId}, _From, State) ->
    Reply=rpc:call(node(),controller,create_pod,[Node,PodId],15000),
    {reply, Reply, State};

handle_call({delete_pod,Node,PodId}, _From, State) ->
    Reply=rpc:call(node(),controller,delete_pod,[Node,PodId],15000),
    {reply, Reply, State};

handle_call({create_container,Pod,PodId,Service}, _From, State) ->
    Reply=rpc:call(node(),controller,create_container,[Pod,PodId,Service],15000),
    {reply, Reply, State};

handle_call({delete_container,Pod,PodId,Service}, _From, State) ->
    Reply=rpc:call(node(),controller,delete_container,[Pod,PodId,Service],15000),
    {reply, Reply, State};

handle_call({stop}, _From, State) ->
    {stop, normal, shutdown_ok, State};

handle_call(Request, From, State) ->
    Reply = {unmatched_signal,?MODULE,?LINE,Request,From},
    {reply, Reply, State}.

%% --------------------------------------------------------------------
%% Function: handle_cast/2
%% Description: Handling cast messages
%% Returns: {noreply, State}          |
%%          {noreply, State, Timeout} |
%%          {stop, Reason, State}            (terminate/2 is called)
%% --------------------------------------------------------------------
handle_cast({check_boards,Interval}, State) ->
    % Ensure that newly started boards are connected and use ping to check if presents
    {ok,AllBoardIds}=rpc:call(node(),nodes_config,get_all_nodes,[],5000),
    PingResult=[{net_adm:ping(list_to_atom(BoardId)),BoardId}||BoardId<-AllBoardIds],
    ActiveBoards=[BoardId||{pong,BoardId}<-PingResult],
    InActive=[BoardId||{pang,BoardId}<-PingResult],
    NewState=#state{active=ActiveBoards,inactive=InActive},
    % Check 
   % case rpc:call(node(),iaas,active_boards,[],5000) of
%	{{active,ActiveBoards},{inactive,InActive}}->
%	    NewState=#state{active=ActiveBoards,inactive=InActive},
%	    {{active,ActiveBoards},{inactive,InActive}};
%	{badrpc,Err}->
%	    NewState=State,
%	    {badrpc,Err};
%	Err->
%	    NewState=State,
%	    {error,Err}
 %   end,
    spawn(fun()->do_poll(Interval) end),
    {noreply, NewState};

handle_cast(Msg, State) ->
    io:format("unmatched match cast ~p~n",[{?MODULE,?LINE,Msg}]),
    {noreply, State}.

%% --------------------------------------------------------------------
%% Function: handle_info/2
%% Description: Handling all non call/cast messages
%% Returns: {noreply, State}          |
%%          {noreply, State, Timeout} |
%%          {stop, Reason, State}            (terminate/2 is called)

handle_info(Info, State) ->
    io:format("unmatched match info ~p~n",[{?MODULE,?LINE,Info}]),
    {noreply, State}.


%% --------------------------------------------------------------------
%% Function: terminate/2
%% Description: Shutdown the server
%% Returns: any (ignored by gen_server)
%% --------------------------------------------------------------------
terminate(_Reason, _State) ->
    ok.

%% --------------------------------------------------------------------
%% Func: code_change/3
%% Purpose: Convert process state when code is changed
%% Returns: {ok, NewState}
%% --------------------------------------------------------------------
code_change(_OldVsn, State, _Extra) ->
    {ok, State}.

%% --------------------------------------------------------------------
%%% Internal functions
%% --------------------------------------------------------------------
%% --------------------------------------------------------------------
%% Function: 
%% Description:
%% Returns: non
%% --------------------------------------------------------------------
do_poll(Interval)->
     timer:sleep(Interval),
    iaas_service:check_boards(Interval),
 %   timer:sleep(Interval).
    ok.

    
    
    

%% --------------------------------------------------------------------
%% Internal functions
%% --------------------------------------------------------------------

%% --------------------------------------------------------------------
%% Internal functions
%% --------------------------------------------------------------------
