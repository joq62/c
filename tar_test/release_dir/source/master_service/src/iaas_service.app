%% This is the application resource file (.app file) for the 'base'
%% application.
{application, iaas_service,
[{description, "iaas_service" },
{vsn, "0.0.1" },
{modules, [iaas_service_app,iaas_service_sup,
	   iaas_service,iaas,
	   node_config]},
{registered,[iaas_service]},
{applications, [kernel,stdlib]},
{mod, {iaas_service_app,[]}},
{start_phases, []}
]}.
