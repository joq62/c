all:
	rm -rf boot/ebin/* boot/src/*~;
	cp /home/pi/erlang/a/source/boot/src/* boot/src;
	erlc -o boot/ebin boot/src/*.erl;
	erl -pa boot/ebin -s boot_board start -sname board_m1
