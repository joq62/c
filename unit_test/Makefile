all:
	rm -rf test_src/*~ test_src/*.beam *.dump;
	rm -rf test_ebin/* ebin/*;
	cp /home/pi/erlang/c/source/lib_service/src/*.* test_src;
	cp /home/pi/erlang/c/source/lib_service/src/*.app test_ebin;	
	cp /home/pi/erlang/c/source/include/*.hrl test_src;
#	copy common macros tpeach src dir 
	cp /home/pi/erlang/c/source/include/*.hrl /home/pi/erlang/c/source/adder_service/src;
	cp /home/pi/erlang/c/source/include/*.hrl /home/pi/erlang/c/source/catalog_service/src;
	cp /home/pi/erlang/c/source/include/*.hrl /home/pi/erlang/c/source/iaas_service/src;
	cp /home/pi/erlang/c/source/include/*.hrl /home/pi/erlang/c/source/lib_service/src;
	cp /home/pi/erlang/c/source/include/*.hrl /home/pi/erlang/c/source/log_service/src;
	cp /home/pi/erlang/c/source/include/*.hrl /home/pi/erlang/c/source/master_service/src;
	cp /home/pi/erlang/c/source/include/*.hrl /home/pi/erlang/c/source/dns_service/src;
	erlc  -D unit_test -D local -I test_src  -o test_ebin test_src/*.erl;
	erl -pa test_ebin -pa * -s unit_test start unit_test_all.spec -sname unit_test_all
unit:
	rm -rf test_src/*~ test_src/*.beam *.dump;
	rm -rf test_ebin/* ebin/*;
	cp /home/pi/erlang/c/source/lib_service/src/*.* test_src;
	cp /home/pi/erlang/c/source/lib_service/src/*.app test_ebin;	
	cp /home/pi/erlang/c/source/include/*.hrl test_src;	
#	copy common macros tpeach src dir 
	cp /home/pi/erlang/c/source/include/*.hrl /home/pi/erlang/c/source/adder_service/src;
	cp /home/pi/erlang/c/source/include/*.hrl /home/pi/erlang/c/source/catalog_service/src;
	cp /home/pi/erlang/c/source/include/*.hrl /home/pi/erlang/c/source/iaas_service/src;
	cp /home/pi/erlang/c/source/include/*.hrl /home/pi/erlang/c/source/lib_service/src;
	cp /home/pi/erlang/c/source/include/*.hrl /home/pi/erlang/c/source/log_service/src;
	cp /home/pi/erlang/c/source/include/*.hrl /home/pi/erlang/c/source/master_service/src;
	cp /home/pi/erlang/c/source/include/*.hrl /home/pi/erlang/c/source/dns_service/src;
	erlc -D unit_test -D local  -I test_src  -o test_ebin test_src/*.erl;
	erl -pa test_ebin -pa * -s unit_test start unit_test.spec -sname unit_test
