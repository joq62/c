{test_files,[{infrastructure,stop,[Computers]},
	      {infrastructure,start,[Computers,LibService]},
	      {test_loader,start,[Apps,Computers,LibService]},
	      {init_iaas,start,[Apps,Computers]},
	      {init_iaas,stop,[]},
	      {test_loader,stop,[Apps,Computers]},
	      {infrastructure,stop,[Computers]}
	    ]
 }.

{apps,[{{service,"dns_service"},{dir,"/home/pi/erlang/c/source"},
	{computer,"master_computer"}},
       {{service,"iaas_service"},{dir,"/home/pi/erlang/c/source"},
	{computer,"master_computer"}}]}.

{computers,[{"master_computer",'master_computer@asus',"localhost",42000},
	    {"w1_computer",'w1_computer@asus',"localhost",42001},
	    {"w2_computer",'w2_computer@asus',"localhost",42002}
	   ]}.
{lib_service,[{{service,"lib_service"},{dir,"/home/pi/erlang/c/source"}}]}.
     
