%% This is the application resource file (.app file) for the 'base'
%% application.
{application, unit_test_staging_service,
[{description, "unit_test_staging_service  " },
{vsn, "1.0.0" },
{modules, 
	  [unit_test_staging_service_app,unit_test_staging_service_sup,unit_test_staging_service]},
{registered,[unit_test_staging_service]},
{applications, [kernel,stdlib]},
{mod, {unit_test_staging_service_app,[]}},
{start_phases, []}
]}.
