{specification, new_test_app}.
{type,application}.
{description, "Specification file for application template" }.
{vsn, "1.0.0" }.
{machine,"machine_w1@asus"}.
{services,[{{service,"t1_service"},{dir,path_t1_service}},
           {{service,"t2_service"},{url,url_t2_service}}]}.
