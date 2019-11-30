-module(rd).
 
-export([
         add_target_resource_type/1,
         add_local_resource/2,
         fetch_resources/1,
         trade_resources/0
	]).

add_target_resource_type(Type) ->
    rd_service:add_target_resource_type(Type).

add_local_resource(Type, Resource) ->
    rd_service:add_local_resource(Type, Resource).

fetch_resources(Type) ->
    rd_service:fetch_resources(Type).

trade_resources() ->
    rd_service:trade_resources().
