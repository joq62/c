%%% -------------------------------------------------------------------
%%% Author  : uabjle
%%% Description : dbase using dets 
%%%
%%% Created : 10 dec 2012
%%% -------------------------------------------------------------------
-module(system_test). 
 
%% --------------------------------------------------------------------
%% Include files
%% --------------------------------------------------------------------


%% --------------------------------------------------------------------

%% External exports

-export([start/1,build/2]).


%% ====================================================================
%% External functions
%% ====================================================================
%% --------------------------------------------------------------------
%% Function:init 
%% Description:
%% Returns: non
%% --------------------------------------------------------------------
-define(TEST_OBJ_ERROR,[{adder_service,unit_test_adder_service},
			{glurk,test_glurk}]).
-define(TEST_OBJ,[ {lib_service,unit_test_lib_service},
		   {lib_service,unit_test_tcp_lib_service},
		   {adder_service,unit_test_adder_service}
		 ]).

-ifdef(error_test).
-define(TEST_CALL,[{test_case,Service,rpc:call(node(),UnitTestCode,test,[],5000)}
				   ||{Service,UnitTestCode}<-?TEST_OBJ_ERROR]).
-else.
-define(TEST_CALL,[{test_case,Service,rpc:call(node(),UnitTestCode,test,[],5000)}
				   ||{Service,UnitTestCode}<-?TEST_OBJ]).
-endif.

start(SystemTestSpec)->
    % Create a unique test dir to store all information and results
    Dir=create_dir(),
    {ok,ObjectTestSpecs}=file:consult(SystemTestSpec),
 %   io:format("~p~n",[{SystemTestSpec,?MODULE,?LINE}]),
    Result=case build_tests(ObjectTestSpecs,Dir,[]) of
	       {ok,ModuleList}->
	%	   io:format("~p~n",[{ModuleList,?MODULE,?LINE}]),
		   ModuleList;
	       {error,Err}->
		   {error,Err};
	       Glurk->
		   io:format("~p~n",[{Glurk,?MODULE,?LINE}])		       
	   end,
    TestResult=[{M,erlang:apply(M,start,[])}||[M,_]<-Result],

io:format("***************************    Unit test result     ***********************~n~n"),
    case [{M,{error,Err}}||{M,{error,Err}}<-TestResult] of
	[]->
	    io:format("OK Unit test Passed ~p~n~n",[TestResult]);
	TestError->
	   io:format("ERROR Unit test failed = ~p~n~n",[TestError])
    end,
    init:stop(),
    ok.


build_tests([],_Dir,BuildResult)->
    Result=case [{error,Err}||{error,Err}<-BuildResult] of
	       []->
		   TestInfoList=[TestInfo||{ok,TestInfo}<-BuildResult],
		   {ok,TestInfoList};
	       CompilerError->
		   {error,CompilerError}
	   end,
    Result;
build_tests([{ObjectSpec,Path}|T],Dir,Acc)->
    Result=case rpc:call(node(),system_test,build,[{ObjectSpec,Path},Dir],5000) of
	       {ok,TestInfo}->
		   
		   {ok,TestInfo};
	       Err->
		   {error,Err}
	   end,
    NewAcc=[Result|Acc],
    build_tests(T,Dir,NewAcc).

build({ObjectSpec,Path},Dir)->
    {ok,I}=file:consult(filename:join(Path,ObjectSpec)),
    % copy the application to be tested
    SrcDir=proplists:get_value(src_dir,I),
    case SrcDir of
	no_app->
	    no_app_to_test; % ok 
	SrcDir->
	    os:cmd("cp "++SrcDir++"/*"++" "++Dir)
    end,
    % copy the test 
    TestSrcDir=proplists:get_value(test_src_dir,I),
    case TestSrcDir of
	[]->
	    no_app_to_test; % should be an error 
	TestSrcDir->
	    os:cmd("cp "++TestSrcDir++"/*"++" "++Dir)
    end,
    {ok,Files}=file:list_dir(Dir),
    FilesToCompile=[filename:join(Dir,File)||File<-Files,filename:extension(File)==".erl"],
    CompileResult=[{c:c(ErlFile,[{outdir,Dir}]),ErlFile}||ErlFile<-FilesToCompile],
    Result= case [{R,File}||{R,File}<-CompileResult,error==R] of
		[]->
		  %  io:format("~p~n",[{compile_ok,?MODULE,?LINE}]),
		    code:add_path(Dir),
		    TestModule=proplists:get_value(test_module,I),
		    _ObjectAppModule=proplists:get_value(object_app_name,I),
		    TimeOut=proplists:get_value(timeout,I),
		    {ok,[TestModule,TimeOut]};
		Err ->
		    io:format("~p~n",[{compile_error,Err,?MODULE,?LINE}]),
		    {error,[compile_error,Err,?MODULE,?LINE]}
	    end,
    Result.
    
    
%% --------------------------------------------------------------------
%% Function:init 
%% Description:
%% Returns: non
%% --------------------------------------------------------------------



%% --------------------------------------------------------------------
%% Function:init 
%% Description:
%% Returns: non
%% --------------------------------------------------------------------

create_dir()->
        % Use date and time 
    timer:sleep(1200), % Secure that there is a new directory becaus o second resolution
    {{Y,M,D},{H,Min,S}}={date(),time()},
    Time=string:join([integer_to_list(H),integer_to_list(Min),integer_to_list(S)],":"),
    Date=string:join([integer_to_list(Y),integer_to_list(M),integer_to_list(D)],"-"),
    DirName=string:join([Time,Date,"test_dir"],"_"),
    file:make_dir(DirName),
    DirName.

%----------------------------------------------
start_service(Node,PodId,ListOfServices)->
    case pod:create(Node,PodId) of
	{error,Err}->
	    io:format(" ~p~n~n",[{error,Err}]);
	{ok,Pod}->
	    ok=container:create(Pod,PodId,ListOfServices)
    end.
    
stop_service(Node,PodId,ListOfServices)->
    {ok,Host}=rpc:call(Node,inet,gethostname,[]),
    PodIdServer=PodId++"@"++Host,
    Pod=list_to_atom(PodIdServer),
    container:delete(Pod,PodId,ListOfServices),
    {ok,stopped}=pod:delete(Node,PodId).
