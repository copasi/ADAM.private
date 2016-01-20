check: test1 test2 test3 test4

test1:
	@./find-pds <../test/test1-input.json | diff -w -q - ../test/test1-output.json || echo "test1 failed"

test2:
	@./find-pds <../test/test2-input.json | diff -w -q - ../test/test2-output.json || echo "test2 failed"

test3:
	@./find-pds <../test/test3-input.json | diff -w -q - ../test/test3-output.json || echo "test3 failed"

test4:
	@./find-pds <../test/test4-input.json | diff -w -q - ../test/test4-output.json || echo "test4 failed"


