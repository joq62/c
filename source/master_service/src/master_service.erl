%%% -------------------------------------------------------------------
%%% Author  : Joq Erlang
%%% Description : master controller
%%% Orchestrait applications and services dependent on application, 
%%% services specifications and availiblity of nodes 
%%% Load and start node_controller_services, lib_service and log_service
%%% on each boards 
%%% master controller holds the central service discovery 
%%%   
%%% Created : 10 dec 2012
%%% -------------------------------------------------------------------
-module(master_service). 

-behaviour(gen_server).
%% --------------------------------------------------------------------
%% Include files
%% --------------------------------------------------------------------


%% --------------------------------------------------------------------
 
%% --------------------------------------------------------------------
%% Key Data structures
%% 
%% --------------------------------------------------------------------
-record(state,{app_list,started,not_started,deployment_log}).

-define(NODES_CONFIG,"nodes.config").
-define(NODES_SIMPLE_CONFIG,"nodes_simple.config").
-define(JOSCA,"josca").

% {{service,Service},{pid,PidService},{node_board,NB},{node_service,NS}}

	  
%% --------------------------------------------------------------------

%% ====================================================================
%% External functions
%% ====================================================================


%% user interface
-export([load_chart/1,update_chart/1,orchistrate/1,
	 status_deployment/0,get_log/0
	 
	]).

%% intermodule 
-export([
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
load_chart(AppList)->
    gen_server:call(?MODULE,{load_chart,AppList},infinity).
update_chart(AppList)->
    gen_server:call(?MODULE,{update_chart,AppList},infinity).
status_deployment()->
    gen_server:call(?MODULE,{status_deployment},infinity).

get_log()->
    gen_server:call(?MODULE,{get_log},infinity).
%%----------------------------------------------------------------------
orchistrate(Interval)->
    gen_server:cast(?MODULE,{orchistrate,Interval}).
%%___________________________________________________________________

%%-----------------------------------------------------------------------


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
    ok=application:start(iaas_service),
    io:format("Dbg ~p~n",[{?MODULE, application_started}]),
    {ok, #state{app_list=[],started=[],not_started=[],deployment_log=[{date(),time(),started,[]}]
	       }}.
    
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

handle_call({load_chart,AppList}, _From, State) ->
    NewLog=[{date(),time(),'applist loaded',[AppList]}|State#state.deployment_log],
    NewState=State#state{app_list=AppList,deployment_log=NewLog},
    {reply, ok, NewState};

handle_call({update_chart,AppList}, _From, State) ->
    NewLog=[{date(),time(),'updated_applist',[AppList]}|State#state.deployment_log],
    NewState=State#state{app_list=AppList,deployment_log=NewLog},    
    {reply, ok, NewState};
 
handle_call({status_deployment}, _From, State) ->
    Reply=ok,
    {reply, Reply, State};

handle_call({get_log}, _From, State) ->
    Reply=State#state.deployment_log,
    {reply, Reply, State};

%---------------------------------------------------------------

handle_call({stop}, _From, State) ->
    iaas_service:stop(),
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

handle_cast({orchistrate, Interval}, State) ->
    glurk=rpc:call(node(),master,orchistrate,[State#state.app_list,State#state.started]),
    spawn(fun()->do_orchistrate_interval(Interval) end),
    io:format("~p~n",[{?MODULE,?LINE,orchistrate, Interval}]),
    {noreply, State};
 %   {noreply, NewState};

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


%% --------------------------------------------------------------------
%% Internal functions
%% --------------------------------------------------------------------
do_orchistrate_interval(Interval)->
    timer:sleep(Interval),
    master_service:orchistrate(Interval).
%% --------------------------------------------------------------------
%% Internal functions
%% --------------------------------------------------------------------
