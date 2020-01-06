%% This is the application resource file (.app file) for the 'base'
%% application.
{application, master_service,
[{description, "master_service" },
{vsn, "0.0.1" },
{modules, [master_service_app,master_service_sup,
	   master_service,master,
	   node_config]},
{registered,[master_service]},
{applications, [kernel,stdlib]},
{mod, {master_service_app,[]}},
{start_phases, []}
]}.
