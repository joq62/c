all:
	rm -rf test_src/*~ test_src/*.beam *.dump;
	rm -rf test_ebin/* ebin/*;
	cp /home/pi/erlang/c/source/lib_service/src/*.* test_src;
	erlc -o test_ebin test_src/*.erl;
	erl -pa test_ebin -pa * -s unit_test_all start -sname unit_test_all
unit:
	rm -rf test_src/*~ test_src/*.beam *.dump;
	rm -rf test_ebin/* ebin/*;
	cp /home/pi/erlang/c/source/lib_service/src/*.* test_src;
	erlc -o test_ebin test_src/*.erl;
	erl -pa test_ebin -pa * -s unit_test start -sname unit_test
