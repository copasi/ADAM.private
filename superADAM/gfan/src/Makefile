check: test1 test2 test3 test5

test1:
	@GFAN_RANDOMSEED=test ./gfan <../test/test1-input.json | diff -w -q - ../test/test1-output.json || echo "test1 failed"
test2:
	@GFAN_RANDOMSEED=test ./gfan <../test/test2-input.json | diff -w -q - ../test/test2-output.json || echo "test2 failed"
test3:
	@GFAN_RANDOMSEED=test ./gfan <../test/test3-input.json | diff -w -q - ../test/test3-output.json || echo "test3 failed"
test5:
	@GFAN_RANDOMSEED=test ./gfan <../test/test5-input.json | diff -w -q - ../test/test5-output.json || echo "test4 failed"
