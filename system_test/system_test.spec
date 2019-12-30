{computers,[{"master_computer",'master_computer@asus',"localhost",42000},
	    {"w1_computer",'w1_computer@asus',"localhost",42001},
	    {"w2_computer",'w2_computer@asus',"localhost",42002}
	   ]}.
{lib_service,[{{service,"lib_service"},{dir,"/home/pi/erlang/c/source"}}]}.

{apps,[{{service,"iaas_service"},{dir,"/home/pi/erlang/c/source"},
	{computer,"master_computer",'master_computer@asus'}}]}.

     
