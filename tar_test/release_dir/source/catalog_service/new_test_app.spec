{app, new_test_app}.
{description, "Specification file for application template" }.
{vsn, "1.0.0" }.
{machine,[{"localshost",12345}]}.
{services,[{{service,"t1_service"},{dir,path_t1_service}},
           {{service,"t2_service"},{url,url_t2_service}}]}.
