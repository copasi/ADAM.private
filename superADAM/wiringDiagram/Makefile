build:
	docker pull algorun/algorun
	cp -r ../share .
	cp test/test1-input.json algorun_info/input_example.txt
	cp test/test1-output.json algorun_info/output_example.txt
	docker build -t algorun/wiring-diagram .

run:
	docker run -p 31333:8765 algorun/wiring-diagram

try:
	open http://$$(docker-machine ip default):31333

check: test1

test1:
	@./src/wiring-diagram <./test/test1-input.json | diff -w -q - ./test/test1-output.json || echo "test1 failed"

