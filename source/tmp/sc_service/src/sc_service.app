%% This is the application resource file (.app file) for the 'base'
%% application.
{application, sc_service,
[{description, "sc_service  " },
{vsn, "1.0.0" },
{modules, 
	  [sc_service_app,sc_service_sup,sc_service,sc]},
{registered,[sc_service]},
{applications, [kernel,stdlib]},
{mod, {sc_service_app,[]}},
{start_phases, []}
]}.
