-module(ets_rd).

-define(ETS_RD,ets_rd_service).
 
-export([
	 debug/0,
         init/0,
	 store_active_nodes/1,get_active_nodes/0,
	 member_node/1,delete_active_node/1,
	 store_local/1,get_locals/0,delete_local/1,get_local/1,
	 store_target/1,get_targets/0,delete_target/1,
	 store_found/1,get_founds/0,delete_found/1,
	 get_resources/1,get_found/1
	]).


init()->
    ets:new(ets_rd_service, [bag, public, named_table]),
    ActiveNodes=[node()|nodes()],
    store_active_nodes(ActiveNodes),
    ok.


debug()->
    ets:match(?ETS_RD,'$1').
%---------------- Found ----------------------------------
store_found(Found)->
    ets:insert(?ETS_RD,[{{found,Found},Found}]).

get_founds()->
    Result=case ets:match(?ETS_RD,{{found,'_'},'$1'}) of
	       []->
		   [];
	       Founds ->
		   [Found||[Found]<-Founds]
	   end,
    Result.
get_resources(Service)->
    Result=case ets:match(?ETS_RD,{{found,{Service,'_'}},{'_','$1'}}) of
	       []->
		   [];
	       Resources ->
		   [Resource||[Resource]<-Resources]
	   end,
    Result.
get_found(Node)->
    Result=case ets:match(?ETS_RD,{{found,{'_',Node}},'$1'}) of
	       []->
		   [];
	       Founds ->
		   [Found||[Found]<-Founds]
	   end,
    Result.

delete_found({Service,Resource})->
    ets:delete(?ETS_RD,{found,{Service,Resource}}).

%---------------- Target ----------------------------------
store_target(Target)->
    ets:insert(?ETS_RD,[{{target,Target},Target}]).

get_targets()->
    Result=case ets:match(?ETS_RD,{{target,'_'},'$1'}) of
	       []->
		   [];
	       Targets ->
		   [Target||[Target]<-Targets]
	   end,
    Result.
delete_target(Target)->
    ets:delete(?ETS_RD,{target,Target}).

%---------------- locals ----------------------------------
store_local(Local)->
    ets:insert(?ETS_RD,[{{local,Local},Local}]).

get_locals()->
    Result=case ets:match(?ETS_RD,{{local,'_'},'$1'}) of
	       []->
		   [];
	       Locals ->
		   [Local||[Local]<-Locals]
	   end,
    Result.
get_local(Service)->
    Result=case ets:match(?ETS_RD,{{local,{Service,'_'}},'$1'}) of
	       []->
		   [];
	       Locals ->
		   [Local||[Local]<-Locals]
	   end,
    Result.

delete_local(Local)->
    ets:delete(?ETS_RD,{local,Local}).


%--------------- nodes -------------------------------

store_active_nodes(ActiveNodes)->
    [ets:insert(?ETS_RD,[{{active_node,Node},Node}])||Node<-ActiveNodes].

get_active_nodes()->
    Result=case ets:match(?ETS_RD,{{active_node,'_'},'$1'}) of
	       []->
		   [];
	       Nodes ->
		   [Node||[Node]<-Nodes]
	   end,
    Result.

member_node(Node)->
    Result=case ets:match(?ETS_RD,{{active_node,Node},'$1'}) of
	       []->
		   false;
	       Nodes ->
		   lists:member([Node],Nodes)
	   end,
    Result.

delete_active_node(Node)->
    ets:delete(?ETS_RD,{active_node,Node}).
