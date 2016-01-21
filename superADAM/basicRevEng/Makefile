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
	@./find-pds <./test/test1-input.json | diff -w -q - ./test/test1-output.json || echo "test1 failed"

test2:
	@./find-pds <./test/test2-input.json | diff -w -q - ./test/test2-output.json || echo "test2 failed"

test3:
	@./find-pds <./test/test3-input.json | diff -w -q - ./test/test3-output.json || echo "test3 failed"

test4:
	@./find-pds <./test/test4-input.json | diff -w -q - ./test/test4-output.json || echo "test4 failed"
