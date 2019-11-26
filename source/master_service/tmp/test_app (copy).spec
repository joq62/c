{specification, test_app}.
{description, "Specification file for application template" }.
{vsn, "1.0.0" }.
{machine,["machine_w1@asus"]}.
{app_dep,[{{app,app2},{dir,"path /test_2_app.spec"}},
	  {{app,app3},{url,"github ... test_3_app.spec"}}]}.
{services,[{{service_id,"t1_service"},{url,"github ...t1.spec"},
	       {service_id,"t2_service"},{dir,"path /t2.spec"}
	      }]}.
