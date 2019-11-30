-module(ets_rd).

-define(ETS_RD,ets_rd_service).
 
-export([
         init/0,
	 store_active_nodes/1,get_active_nodes/0,
	 member_node/1,delete_active_node/1,
	 store_local/1,get_locals/0,delete_local/1
	]).


init()->
    ets:new(ets_rd_service, [bag, named_table]),
    ActiveNodes=[node()|nodes()],
    store_active_nodes(ActiveNodes),
    ok.

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
