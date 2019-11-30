{application, rd_service,
 [{description, "A simple resource discovery system"},
  {vsn, "0.1.0"},
  {modules, [rd,
             rd_service_app,
             rd_service_sup,
	     rd_service]},
  {registered, [rd_service_sup, rd_service]},
  {applications, [kernel, stdlib]},
  {mod, {rd_service_app, []}}
 ]}.
