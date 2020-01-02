%%% -------------------------------------------------------------------
%%% Author  : uabjle
%%% Description : dbase using dets 
%%%
%%% Created : 10 dec 2012
%%% -------------------------------------------------------------------
-module(catalog_unit_test). 
  
%% --------------------------------------------------------------------
%% Include files
%% --------------------------------------------------------------------
% 

%% --------------------------------------------------------------------
-define(SERVER_ID,"test_tcp_server").
%% External exports
-export([test/0,
	 init_test/0,start_catalog_test/0,
	 catalog_1_test/0,catalog_2_test/0,  
	 stop_catalog_test/0]).

%-compile(export_all).

-define(TIMEOUT,1000*15).

%% ====================================================================
%% External functions
%% ====================================================================
test()->
    TestList=[init_test,start_catalog_test,
	      catalog_1_test,catalog_2_test,  
	      stop_catalog_test 
	     ],
    test_support:execute(TestList,?MODULE,?TIMEOUT).
	


%% --------------------------------------------------------------------
%% Function:init 
%% Description:
%% Returns: non
%% --------------------------------------------------------------------
init_test()->
     {pong,_,catalog_service}=catalog_service:ping(),
    ok.
    
%------------------  -------


start_catalog_test()->
    App1=[{app,app1},
	  {description,"Specification file for application template"},
	  {vsn,"1.0.0"},
	  {machine,[{"localhost",42001}]},
	  {services,[{{service,"t10_service"},{dir,path_t10_service}},
		     {{service,"t11_service"},{url,url_t11_service}}]}],
    App2=[{app,app2},
	  {description,"Specification file for application template"},
	  {vsn,"1.0.0"},
	  {machine,[{"localhost",42002}]},
	  {services,[{{service,"t20_service"},{dir,path_t20_service}},
		     {{service,"t21_service"},{url,url_t21_service}}]}],
    App3=[{app,app3},
	  {description,"Specification file for application template"},
	  {vsn,"1.0.0"},
	  {machine,[{"localhost",42003}]},
	  {services,[{{service,"t30_service"},{dir,path_t30_service}},
		     {{service,"t31_service"},{url,url_t31_service}}]}],

    []=catalog_service:all(),
    catalog_service:add(App1),
    [{app_spec,
      app1,
      "Specification file for application template","1.0.0",
      [{"localhost",42001}],
      [{{service,"t10_service"},{dir,path_t10_service}},
       {{service,"t11_service"},{url,url_t11_service}}]}]=catalog_service:all(),
    catalog_service:add(App2),
    catalog_service:add(App3),

    TestPattern=[{app_spec,app1,
		  "Specification file for application template",
		  "1.0.0",
		  [{"localhost",42001}],
		  [{{service,"t10_service"},{dir,path_t10_service}},
		   {{service,"t11_service"},{url,url_t11_service}}]},
		 {app_spec,app2,
		  "Specification file for application template",
		  "1.0.0",
		  [{"localhost",42002}],
		  [{{service,"t20_service"},{dir,path_t20_service}},
		   {{service,"t21_service"},{url,url_t21_service}}]},
		 {app_spec,app3,
		  "Specification file for application template",
		  "1.0.0",
		  [{"localhost",42003}],
		  [{{service,"t30_service"},{dir,path_t30_service}},
		   {{service,"t31_service"},{url,url_t31_service}}]}],
    L=catalog_service:all(),		  
    TestL=[R||{_,R,_,_,_,_}<-L,
		(R=:=app1)or(R=:=app2)or(R=:=app3)],
    ok=case lists:flatlength(TestL) of
	   3->
	       ok;
	   _->
	       {"Result of call",L,"---------------","test pattern",TestPattern}
       end,
   ok.

catalog_1_test()->
    catalog_service:delete(app2,"1.0.0"),
    TestPattern=[{app_spec,app1,
		  "Specification file for application template",
		  "1.0.0",
		  [{"localhost",42001}],
		  [{{service,"t10_service"},{dir,path_t10_service}},
		   {{service,"t11_service"},{url,url_t11_service}}]},
		 {app_spec,app3,
		  "Specification file for application template",
		  "1.0.0",
		  [{"localhost",42003}],
		  [{{service,"t30_service"},{dir,path_t30_service}},
		   {{service,"t31_service"},{url,url_t31_service}}]}],
    L=catalog_service:all(),		  
    TestL=[R||{_,R,_,_,_,_}<-L,
		(R=:=app1)or(R=:=app2)or(R=:=app3)],
    ok=case lists:flatlength(TestL) of
	   2->
	       ok;
	   _->
	       {"Result of call",L,"---------------","test pattern",TestPattern}
       end,
    
    ok.

catalog_2_test()->
    [{app_spec,
      app1,
      "Specification file for application template","1.0.0",
      [{"localhost",42001}],
      [{{service,"t10_service"},{dir,path_t10_service}},
       {{service,"t11_service"},{url,url_t11_service}}]}]=catalog_service:get(app1,"1.0.0"),
    []=catalog_service:get(app1,"1.0.1"),
    []=catalog_service:get(app2,"1.0.0"),
ok.

stop_catalog_test()->
    ok.


%**************************************************************
