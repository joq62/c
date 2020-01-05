## set the paths for a default setup

all:
	erlc -o ../ebin src/*.erl;
	erl -pa ../ebin
clean:
	rm -rf */*~ src/*.beam  *~ *.dump
make:
	erlc -o ../ebin src/*.erl;
test:
	erlc -o ../ebin src/*.erl;
	erl -pa ../ebin -s dfs_test test

