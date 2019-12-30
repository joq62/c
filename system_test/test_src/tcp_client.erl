%%% -------------------------------------------------------------------
%%% Author  : uabjle
%%% Description : dbase using dets 
%%%
%%% Created : 10 dec 2012
%%% -------------------------------------------------------------------
-module(tcp_client).
  


%% --------------------------------------------------------------------
%% Include files
%% --------------------------------------------------------------------

%% --------------------------------------------------------------------
-define (CLIENT_SETUP,[binary, {packet,4}]).
-define (TIMEOUT_TCPCLIENT, 120*1000).

-define(KEY_M_OS_CMD,89181808).
-define(KEY_F_OS_CMD,"95594968").
-define(KEY_MSG,'100200273').

%% External exports
-export([connect/2,disconnect/1,
	 session_call/2,session_call/3,
	 get_msg/2
	]).

-export([call/2,call/3,
	 cast/3
	]).


%% ====================================================================
%% External functions
%% ====================================================================
connect(IpAddr,Port)->
    Self=self(),
    Pid=spawn(fun()-> session(IpAddr,Port,Self) end),
    Pid.

session_call(Pid,{M,F,A})->
    S=self(),
    Pid!{S,{call,{M,F,A}}}.

session_call(Pid,Pod,{M,F,A})->
    S=self(),
    Pid!{S,{Pod,call,{M,F,A}}}.

disconnect(Pid)->
    S=self(),
    Pid!{S,{disconnect}}.

get_msg(Pid,Timeout)->
    Result=receive
	       {Pid,{msg,R}}->
		   R;
	       {Pid,{error,Err}} ->
		   {error,Err};
	       Unmatched ->
		   {error,[unmatched,Unmatched]}
	   after Timeout ->
		   {error,[get_msg_timeout,?MODULE,?LINE]}
	   end,
    Result.

session(IpAddr,Port,Parent)->
    case gen_tcp:connect(IpAddr,Port,?CLIENT_SETUP) of
	 {ok,Socket}->
	    session_loop(Socket,Parent);
	{error,Err}->
	    Parent!{self(),{error,[Err]}}
    end.

session_loop(Socket,Parent)->
    receive
	{tcp,Socket,Bin}->
	    case binary_to_term(Bin) of
		{?KEY_MSG,R}->
		    Parent!{self(),{msg,R}};
		Err->
		    Parent!{self(),{error,[Err]}}
	    end,
	    session_loop(Socket,Parent);
	{tcp_closed, Socket}->
	    Parent!{self(),{error,[tcp_closed]}};
	{Parent,{call,{M,F,A}}}->
	    ok=send2(Socket,{M,F,A}),
	    session_loop(Socket,Parent);
	{Parent,{Pod,call,{M,F,A}}}->
	    ok=send2(Socket,Pod,{M,F,A}),
	    session_loop(Socket,Parent);
	{Parent,{disconnect}}->
	    gen_tcp:close(Socket)
    after ?TIMEOUT_TCPCLIENT ->
	    Parent!{self(),{error,[?MODULE,?LINE,tcp_timeout]}}
    end.
    

send2(Socket,{M,F,A})->
    Msg=case {M,F,A} of
	    {os,cmd,A}->
		{?KEY_MSG,call,{?KEY_M_OS_CMD,?KEY_F_OS_CMD,A}};
	    {M,F,A}->
		{?KEY_MSG,call,{M,F,A}}
	end, 
    gen_tcp:send(Socket,term_to_binary(Msg)).

send2(Socket,Pod,{M,F,A})->
    Msg=case {M,F,A} of
	    {os,cmd,A}->
		{?KEY_MSG,Pod,call,{?KEY_M_OS_CMD,?KEY_F_OS_CMD,A}};
	    {M,F,A}->
		{?KEY_MSG,Pod,call,{M,F,A}}
	end, 
    gen_tcp:send(Socket,term_to_binary(Msg)).

%% --------------------------------------------------------------------
%% Function: 
%% Description:
%% Returns: non
%% --------------------------------------------------------------------
call({IpAddr,Port},{M,F,A})->
    Msg=case {M,F,A} of
	    {os,cmd,A}->
		{?KEY_MSG,call,{?KEY_M_OS_CMD,?KEY_F_OS_CMD,A}};
	    {M,F,A}->
		{?KEY_MSG,call,{M,F,A}}
	end,
    send(IpAddr,Port,Msg).

call({IpAddr,Port},Pod,{M,F,A})->
    Msg=case {M,F,A} of
	    {os,cmd,A}->
		{?KEY_MSG,Pod,call,{?KEY_M_OS_CMD,?KEY_F_OS_CMD,A}};
	    {M,F,A}->
		{?KEY_MSG,Pod,call,{M,F,A}}
	end,
    send(IpAddr,Port,Msg).

send(IpAddr,Port,Msg)->
    case gen_tcp:connect(IpAddr,Port,?CLIENT_SETUP) of
	{ok,Socket}->
	    ok=gen_tcp:send(Socket,term_to_binary(Msg)),
	    receive
		{tcp,Socket,Bin}->
		    Result=case binary_to_term(Bin) of
			       {?KEY_MSG,R}->
				   R;
			       Err->
				   Err
			   end;
		{tcp_closed, Socket}->
		    Result={error,tcp_closed}
	    after ?TIMEOUT_TCPCLIENT ->
		    Result={error,[?MODULE,?LINE,tcp_timeout,IpAddr,Port,Msg]}
	    end,
	    ok=gen_tcp:close(Socket) ;
	{error,Err}->
	    Result={error,Err}
    end,
   Result.
			   
%% --------------------------------------------------------------------
%% Function: 
%% Description:
%% Returns: non
%% --------------------------------------------------------------------
cast({IpAddr,Port},Pod,{M,F,A})->
    spawn(fun()->do_cast({IpAddr,Port},Pod,{M,F,A}) end),
    ok.
do_cast({IpAddr,Port},Pod,{M,F,A})->
    Msg=case {M,F,A} of
	    {os,cmd,A}->
		{?KEY_MSG,Pod,cast,{?KEY_M_OS_CMD,?KEY_F_OS_CMD,A}};
	    {M,F,A}->
		{?KEY_MSG,Pod,cast,{M,F,A}}
	end,
  case gen_tcp:connect(IpAddr,Port,?CLIENT_SETUP) of
	{ok,Socket}->
	    ok=gen_tcp:send(Socket,term_to_binary(Msg)),
	    receive
		{tcp,Socket,Bin}->
		    Result=case binary_to_term(Bin) of
			       {?KEY_MSG,R}->
				   R;
			       Err->
				   Err
			   end,
		    gen_tcp:close(Socket);
		{tcp_closed, Socket}->
		    Result={error,tcp_closed}
	    after ?TIMEOUT_TCPCLIENT ->
		    Result={error,[?MODULE,?LINE,tcp_timeout,IpAddr,Port,Msg]},
		    gen_tcp:close(Socket)
	    end;
	{error,Err}->
	    Result={error,Err}
    end,
    Result.
