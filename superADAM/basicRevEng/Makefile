build:
	docker pull algorun/algorun
	cp -r ../share .
	cp test/test1-input.json algorun_info/input_example.txt
	cp test/test1-output.json algorun_info/output_example.txt
	docker build -t algorun/basic-reveng .

run:
	docker run -p 31334:8765 --rm --name basic-reveng algorun/basic-reveng

stop:
	docker stop basic-reveng

try:
	open http://$$(docker-machine ip default):31334

check: test1 test2 test3 test4

test1:
	@./src/find-pds <./test/test1-input.json | diff -w -q - ./test/test1-output.json || echo "test1 failed"
test2:
	@./src/find-pds <./test/test2-input.json | diff -w -q - ./test/test2-output.json || echo "test2 failed"
test3:
	@./src/find-pds <./test/test3-input.json | diff -w -q - ./test/test3-output.json || echo "test3 failed"
test4:
	@./src/find-pds <./test/test4-input.json | diff -w -q - ./test/test4-output.json || echo "test4 failed"

test-curl: test-curl-1 test-curl-2 test-curl-3 test-curl-4

test-curl-1:
	@curl -F input=@test/test1-input.json http://$$(docker-machine ip default):31334/v1/run >foo.json 2> /dev/null
	@diff -w -q foo.json test/test1-output.json || echo "curl test1 failed: make sure you have done 'make run'"
test-curl-2:
	@curl -F input=@test/test2-input.json http://$$(docker-machine ip default):31334/v1/run >foo.json 2> /dev/null
	@diff -w -q foo.json test/test2-output.json || echo "curl test2 failed: make sure you have done 'make run'"
test-curl-3:
	@curl -F input=@test/test3-input.json http://$$(docker-machine ip default):31334/v1/run >foo.json 2> /dev/null
	@diff -w -q foo.json test/test3-output.json || echo "curl test3 failed: make sure you have done 'make run'"
test-curl-4:
	@curl -F input=@test/test4-input.json http://$$(docker-machine ip default):31334/v1/run >foo.json 2> /dev/null
	@diff -w -q foo.json test/test4-output.json || echo "curl test4 failed: make sure you have done 'make run'"

test-direct: test-direct-1 test-direct-2 test-direct-3 test-direct-4

test-direct-1:
	docker exec -i basic-reveng /bin/algorun < test/test1-input.json | diff -w -q - test/test1-output.json || echo "direct test1 failed: make sure you have done 'make run'"
test-direct-2:
	docker exec -i basic-reveng /bin/algorun < test/test2-input.json | diff -w -q - test/test2-output.json || echo "direct test2 failed: make sure you have done 'make run'"
test-direct-3:
	docker exec -i basic-reveng /bin/algorun < test/test3-input.json | diff -w -q - test/test3-output.json || echo "direct test3 failed: make sure you have done 'make run'"
test-direct-4:
	docker exec -i basic-reveng /bin/algorun < test/test4-input.json | diff -w -q - test/test4-output.json || echo "direct test4 failed: make sure you have done 'make run'"
