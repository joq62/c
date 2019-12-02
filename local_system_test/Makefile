all:
	rm -rf test_src/*~ test_src/*.beam *.dump;
	rm -rf test_ebin/*;
	erlc -o test_ebin test_src/*.erl;
	erl -pa test_ebin -pa * -s local_system_test start -sname local_system_test
