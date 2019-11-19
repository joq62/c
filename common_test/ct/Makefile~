all:
	rm -rf /home/pi/erlang/a/source/*/test_src/*~;
	rm -rf /home/pi/erlang/a/source/*/src/*~;
	rm -rf /home/pi/erlang/a/source/*/src/*.beam;
	rm -rf src_ebin/* test_ebin/*;
	erlc -o test_ebin /home/pi/erlang/a/source/*/test_src/*.erl;
	erlc -o src_ebin /home/pi/erlang/a/source/*/src/*.erl;
	erlc -o test_ebin test_suites/*/*.erl;
	cp /home/pi/erlang/a/source/*/src/*.app src_ebin;
	erl -pa src_ebin -pa test_ebin -sname common_test

adder:
	rm -rf /home/pi/erlang/a/source/*/test_src/*~;
	rm -rf /home/pi/erlang/a/source/*/src/*~;
	rm -rf /home/pi/erlang/a/source/*/src/*.beam;
	rm -rf ct_run.*;
	cp /home/pi/erlang/a/source/adder_service/src/* test_suites/adder_service
