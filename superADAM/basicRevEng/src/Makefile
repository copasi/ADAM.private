check: test1 test2 test3

test1:
	@./find-pds <../test/test1-input.json | diff -q - ../test/test1-output.json || echo "test1 failed"

test2:
	@./find-pds <../test/test2-input.json | diff -q - ../test/test2-output.json || echo "test2 failed"

test3:
	@./find-pds <../test/test3-input.json | diff -q - ../test/test3-output.json || echo "test3 failed"
