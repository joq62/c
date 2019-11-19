all:
	rm -rf ebin/* src/*~;
	erlc -o ebin src/*.erl;
	erl -pa ebin -s controller start -sname controller

test:
	rm -rf ebin/* src/*~ test_ebin/* test_src/*~;
	erlc -o ebin src/*.erl;
	cp src/*.app ebin;
	erlc -o test_ebin test_src/*.erl;
	erl -pa ebin -pa test_ebin -s test_master_service test -sname test_master_service
