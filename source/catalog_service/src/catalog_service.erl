%%% -------------------------------------------------------------------
%%% Author  : Joq Erlang
%%%  
%%% Created : 10 dec 2012
%%% -------------------------------------------------------------------
-module(catalog_service). 

-behaviour(gen_server).
%% --------------------------------------------------------------------
%% Include files
%% --------------------------------------------------------------------

%% --------------------------------------------------------------------
%% Include files
%% --------------------------------------------------------------------

-include("common_macros.hrl").
%% --------------------------------------------------------------------
%% Key Data structures
%% 
%% --------------------------------------------------------------------
-record(state,{}).

%% --------------------------------------------------------------------
%% Exported functions
%% --------------------------------------------------------------------

%% dns functions 
-export([add/1,delete/2,get/2,all/0,
	 ping/0,
	 delete/5,
	 expired/0,delete_expired/0,
	 clear/0,
	 heart_beat/0
	]
      ).


-export([start/0,
	 stop/0
	]).

%% gen_server callbacks
-export([init/1, handle_call/3, handle_cast/2, handle_info/2, terminate/2, code_change/3]).

%% ====================================================================
%% External functions
%% ====================================================================

%% Gen server functions

start()-> gen_server:start_link({local, ?MODULE}, ?MODULE, [], []).

stop()-> gen_server:call(?MODULE, {stop},infinity).



%%-------------------- Direct call -----------------------------------
 


%%--------------------- Server call ------------------------------------
ping()->
    gen_server:call(?MODULE,{ping},infinity).

add(AppSpec)->
    gen_server:call(?MODULE,{add,AppSpec},infinity).  
delete(App,Vsn)->
    gen_server:call(?MODULE,{delete,App,Vsn},infinity).
get(App,Vsn)->
    gen_server:call(?MODULE,{get,App,Vsn},infinity).
all()->
    gen_server:call(?MODULE,{all},infinity).
    


expired()-> 
    gen_server:call(?MODULE, {expired},infinity).
clear()->
    gen_server:call(?MODULE,{clear},infinity).  

delete_expired()->
    gen_server:call(?MODULE,{delete_expired},infinity).  
    

delete(ServiceId,IpAddr,Port,Pod,Time)->
    gen_server:call(?MODULE,{delete,ServiceId,IpAddr,Port,Pod,Time},infinity).  
heart_beat()->
    gen_server:call(?MODULE, {heart_beat},infinity).

%%----------------------Server cast --------------------------------------

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
    catalog_lib:init(),
    spawn(fun()-> local_heart_beat(?HB_TIMEOUT) end), 


    io:format("Started Service  ~p~n",[{?MODULE}]),
   {ok, #state{}}. 
    
%% --------------------------------------------------------------------
%% Function: handle_call/3
%% Description: Handling call messages
%% Returns: {reply, Reply, State}          |
%%          {reply, Reply, State, Timeout} |
%%          {noreply, State}               |
%%          {noreply, State, Timeout}      |
%%          {stop, Reason, Reply, State}   | (terminate/2 is called)
%%          {stop, Reason, State}            (terminate/2 is called)
%% --------------------------------------------------------------------
handle_call({ping},_From,State) ->
    Reply={pong,node(),?MODULE},
    {reply, Reply, State};

handle_call({add,AppSpec},_From,State) ->
    Reply=rpc:call(node(),catalog_lib,add,[AppSpec]),
    {reply, Reply, State};

handle_call({delete,App,Vsn},_From,State) ->
    Reply=rpc:call(node(),catalog_lib,delete,[App,Vsn]),
    {reply, Reply, State};

handle_call({get,App,Vsn},_From,State) ->
    Reply=rpc:call(node(),catalog_lib,get,[App,Vsn]),
    {reply, Reply, State};

handle_call({all},_From,State) ->
    Reply=rpc:call(node(),catalog_lib,all,[]),
    {reply, Reply, State};


handle_call({clear},_From,State) ->
    Reply=rpc:call(node(),dns_lib,clear,[]),
    {reply, Reply, State};

handle_call({expired}, _From, State) ->
    Reply=rpc:call(node(),dns_lib,expired,[]),
   {reply, Reply, State};

handle_call({delete_expired}, _From, State) ->
    Reply=rpc:call(node(),dns_lib,delete_expired,[]),
    {reply, Reply, State};

handle_call({heart_beat}, _From, State) ->
    Reply=ok,
   {reply, Reply, State};
    
handle_call({stop}, _From, State) ->
    {stop, normal, shutdown_ok, State};

handle_call(Request, From, State) ->
    io:format("unmatched  ~p~n",[{time(),?MODULE,?LINE,Request}]),
     Reply = {unmatched_signal,?MODULE,Request,From},
    {reply, Reply, State}.

%% --------------------------------------------------------------------
%% Function: handle_cast/2
%% Description: Handling cast messages
%% Returns: {noreply, State}          |
%%          {noreply, State, Timeout} |
%%          {stop, Reason, State}            (terminate/2 is called)
%% --------------------------------------------------------------------
handle_cast({clear}, State) ->
    rpc:call(node(),dns_lib,clear,[]),
    {noreply, State};

handle_cast({delete_expired}, State) ->
    rpc:call(node(),dns_lib,delete_expired,[]),
    {noreply, State};

handle_cast({add,ServiceId,IpAddr,Port,Pod}, State) ->
    rpc:call(node(),dns_lib,add,[ServiceId,IpAddr,Port,Pod]),
    {noreply, State};

handle_cast({delete,ServiceId,IpAddr,Port,Pod}, State) ->
    rpc:call(node(),dns_lib,delete,[ServiceId,IpAddr,Port,Pod]),
    {noreply, State};

handle_cast({delete,ServiceId,IpAddr,Port,Pod,Time}, State) ->
    rpc:call(node(),dns_lib,delete,[ServiceId,IpAddr,Port,Pod,Time]),
    {noreply, State};

handle_cast(Msg, State) ->
    io:format("unmatched match cast ~p~n",[{time(),?MODULE,?LINE,Msg}]),
    {noreply, State}.

%% --------------------------------------------------------------------
%% Function: handle_info/2
%% Description: Handling all non call/cast messages
%% Returns: {noreply, State}          |
%%          {noreply, State, Timeout} |
%%          {stop, Reason, State}            (terminate/2 is called)
%% --------------------------------------------------------------------


handle_info(Info, State) ->
    io:format("unmatched match cast ~p~n",[{time(),?MODULE,?LINE,Info}]),
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
    

%% --------------------------------------------------------------------
%% Function: 
%% Description:
%% Returns: non
%% --------------------------------------------------------------------
local_heart_beat(Interval)->
  %  io:format(" ~p~n",[{?MODULE,?LINE}]),
    timer:sleep(Interval),
    ?MODULE:heart_beat(),
    spawn(fun()-> local_heart_beat(Interval) end).
%% --------------------------------------------------------------------
%% Function: 
%% Description:
%% Returns: non
%% --------------------------------------------------------------------
