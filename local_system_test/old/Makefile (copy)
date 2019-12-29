all:
	rm -rf */ebin/* ../source/*/src/*~ ../source/*/src/*.beam;
	rm -rf ../source/*/test_src/*~ ../source/*/test_src/*.beam;
	rm -rf test_ebin/*;
	rm -rf *.dump unit_test_src/*~ unit_test_src/*.beam;
	erlc -o ebin ../source/*/src/*.erl;
	cp ../source/*/src/*.app ebin;
	erlc -o test_ebin ../source/*/test_src/*.erl;
	erlc -o test_ebin unit_test_src/*.erl;
	erl -pa ebin -pa test_ebin -s unit_test start -sname unit_test
error:
	rm -rf */ebin/* ../source/*/src/*~ ../source/*/src/*.beam;
	rm -rf ../source/*/test_src/*~ ../source/*/test_src/*.beam;
	rm -rf test_ebin/*;
	rm -rf *.dump unit_test_src/*~ unit_test_src/*.beam;
	erlc -o ebin ../source/*/src/*.erl;
	cp ../source/*/src/*.app ebin;
	erlc -Derror_test -o test_ebin ../source/*/test_src/*.erl;
	erlc -Derror_test -o test_ebin unit_test_src/*.erl;
	erl -pa ebin -pa test_ebin -s unit_test start -sname unit_test
