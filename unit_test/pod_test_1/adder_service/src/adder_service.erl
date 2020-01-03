%%% -------------------------------------------------------------------
%%% Author  : Joq Erlang
%%% Description : test application calc
%%%  
%%% Created : 10 dec 2012
%%% -------------------------------------------------------------------
-module(adder_service). 

-behaviour(gen_server).
%% --------------------------------------------------------------------
%% Include files
%% --------------------------------------------------------------------
-include("common_macros.hrl").
%% --------------------------------------------------------------------

%% --------------------------------------------------------------------
%% Key Data structures
%% 
%% --------------------------------------------------------------------
-record(state,{start_result,myip,dns_address,dns_socket}).

%% Definitions 

%% --------------------------------------------------------------------




-export([add/2,
	 start_result/0
	]).

-export([start/0,
	 stop/0,
	 ping/0,
	 heart_beat/1
	]).

%% gen_server callbacks
-export([init/1, handle_call/3,handle_cast/2, handle_info/2, terminate/2, code_change/3]).


%% ====================================================================
%% External functions
%% ====================================================================

%% Asynchrounus Signals



%% Gen server functions

start()-> gen_server:start_link({local, ?MODULE}, ?MODULE, [], []).
stop()-> gen_server:call(?MODULE, {stop},infinity).



%%-----------------------------------------------------------------------
start_result()->
    gen_server:call(?MODULE, {start_result},infinity).
ping()->
    gen_server:call(?MODULE, {ping},infinity).

add(A,B)->
    gen_server:call(?MODULE, {add,A,B},infinity).


%%-----------------------------------------------------------------------
heart_beat(Interval)->
    gen_server:cast(?MODULE, {heart_beat,Interval}).


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
    % Update Dns
    timer:sleep(5000),
    Start=case rpc:call(node(),lib_service,dns_address,[],500) of
	      {error,Err}->
		  {ok, #state{start_result= {error,Err}}};
	      {DnsIpAddr,DnsPort}->
		  Y=rpc:call(node(),lib_service,myip,[],500),
	%	  {MyIpAddr,MyPort}=Y,
		 % {MyIpAddr,MyPort}=lib_service:myip(),
		  {_,Socket}=rpc:call(node(),tcp_client,connect,[DnsIpAddr,DnsPort],2000),
		 % {_,Socket}=tcp_client:connect(DnsIpAddr,DnsPort),
		%  Y=glurk,
		 % Z=rpc:call(node(),tcp_client,connect,[DnsIpAddr,DnsPort],2000),
		 % {Y,_}=Z,
		 % ok=Y,
		%  {ok,Socket}=rpc:call(node(),tcp_client,connect,[DnsIpAddr,DnsPort],2000),
		  Z=rpc:call(node(),tcp_client,cast,[Socket,{dns_service,add,[atom_to_list(?MODULE),"localhost",50000,node()]}]),
		  %spawn(fun()->h_beat(?HB_TIMEOUT) end),  
		 % {ok, #state{myip={MyIpAddr,MyPort},dns_address={DnsIpAddr,DnsPort},
		%	      dns_socket=Socket}};
		  {ok, #state{start_result={Y,Z}}};
	      X ->
		  {ok, #state{start_result={X,?LINE}}} 		  
	  end,   
    Start.
  %    {ok, #state{}}.
    
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
handle_call({start_result}, _From, State) ->
     Reply=State#state.start_result,
    {reply, Reply, State};

handle_call({ping}, _From, State) ->
     Reply={pong,node(),?MODULE},
    {reply, Reply, State};

handle_call({add,A,B}, _From, State) ->
     Reply=rpc:call(node(),adder,add,[A,B]),
    {reply, Reply, State};


handle_call({stop}, _From, State) ->
    tcp_client:disconnect(State#state.dns_socket),
    {stop, normal, shutdown_ok, State};

handle_call(Request, From, State) ->
    Reply = {unmatched_signal,?MODULE,Request,From},
    {reply, Reply, State}.

%% --------------------------------------------------------------------
%% Function: handle_cast/2
%% Description: Handling cast messages
%% Returns: {noreply, State}          |
%%          {noreply, State, Timeout} |
%%          {stop, Reason, State}            (terminate/2 is called)
%% --------------------------------------------------------------------
handle_cast({heart_beat,Interval}, State) ->
    {MyIpAddr,MyPort}=State#state.myip,
    tcp_client:cast(State#state.dns_socket,{dns_service,add,[atom_to_list(?MODULE),MyIpAddr,MyPort,node()]}),
    
    spawn(fun()->h_beat(Interval) end),      
    {noreply, State};

handle_cast(Msg, State) ->
    io:format("unmatched match cast ~p~n",[{?MODULE,?LINE,Msg}]),
    {noreply, State}.

%% --------------------------------------------------------------------
%% Function: handle_info/2
%% Description: Handling all non call/cast messages
%% Returns: {noreply, State}          |
%%          {noreply, State, Timeout} |
%%          {stop, Reason, State}            (terminate/2 is called)
%% --------------------------------------------------------------------
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
h_beat(Interval)->
    timer:sleep(Interval),
    rpc:cast(node(),?MODULE,heart_beat,[Interval]).

%% --------------------------------------------------------------------
%% Internal functions
%% --------------------------------------------------------------------

%% --------------------------------------------------------------------
%% Function: 
%% Description:
%% Returns: non
%% --------------------------------------------------------------------

