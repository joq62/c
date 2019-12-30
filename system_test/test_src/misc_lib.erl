%%% -------------------------------------------------------------------
%%% Author  : uabjle
%%% Description : dbase using dets 
%%%
%%% Created : 10 dec 2012
%%% -------------------------------------------------------------------
-module(misc_lib).
  


%% --------------------------------------------------------------------
%% Include files
%% --------------------------------------------------------------------

%% --------------------------------------------------------------------

%% External exports

-compile(export_all).


%% ====================================================================
%% External functions
%% ====================================================================
%% --------------------------------------------------------------------
%% Function: 
%% Description:
%% Returns: non
%% --------------------------------------------------------------------
get_node_by_id(Id)->
    {ok,Host}=inet:gethostname(),
    list_to_atom(Id++"@"++Host).
%% --------------------------------------------------------------------
%% Function: 
%% Description:
%% Returns: non
%% --------------------------------------------------------------------
check_pattern_test(TestObject,TestPattern)->
    % find equal, find difference 
    % keep difference L1=:=L2 if L1==L2==[]
    
    
    [match(Object,TestPattern)||Object<-TestObject].

match(Object,ListTuple)->
    [match_tuple(Object,TestTuple)||TestTuple<-ListTuple].
match_tuple(T,T)-> 
    {true,T,T};
match_tuple(T1,T2)->
    {false,T1,T2}.
