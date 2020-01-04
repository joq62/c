{test_files,[{infrastructure,stop},
	     {infrastructure,start},
	      {loader,start},
	     {init_iaas,start},
	     {dns,start},	     
	     {infrastructure,stop}
	    ]}.

{apps,[{{service,"dns_service"},{dir,"/home/pi/erlang/c/source"},
	{computer,"master_computer"}},
       {{service,"iaas_service"},{dir,"/home/pi/erlang/c/source"},
	{computer,"master_computer"}}]}.

{computers,[{"master_computer",'master_computer@asus',"localhost",42000},
	    {"w1_computer",'w1_computer@asus',"localhost",50001},
	    {"w2_computer",'w2_computer@asus',"localhost",50002}
	   ]}.
{lib_service,[{{service,"lib_service"},{dir,"/home/pi/erlang/c/source"}}]}.
