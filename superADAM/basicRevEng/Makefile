TESTS = test1 test2 test3 test4
PORT = 31334
COMMAND = ./src/find-pds
CONTAINER_NAME = basic-reveng

build:
	docker pull algorun/algorun
	cp -r ../share .
	cp test/test1-input.json algorun_info/input_example.txt
	cp test/test1-output.json algorun_info/output_example.txt
	docker build -t algorun/$(CONTAINER_NAME) .

run:
	docker run -p $(PORT):8765 --rm --name $(CONTAINER_NAME) algorun/$(CONTAINER_NAME)

stop:
	docker stop $(CONTAINER_NAME)

try:
	open http://$$(docker-machine ip default):$(PORT)

TESTS_OUT = $(addprefix ./test/, $(addsuffix -check.out, $(TESTS)))
TESTS_CURL = $(addprefix ./test/, $(addsuffix -curl.out, $(TESTS)))
TESTS_DIRECT = $(addprefix ./test/, $(addsuffix -direct.out, $(TESTS)))

check: $(TESTS_OUT)
check-curl: $(TESTS_CURL)
check-direct: $(TESTS_DIRECT)

%-check.out : %-input.json
	@$(COMMAND) < $< > $@
	@diff -w -q $@ $*-output.json || echo "test $* failed"

%-curl.out : %-input.json
	@curl -F input=@$< http://$$(docker-machine ip default):$(PORT)/v1/run >$@ 2> /dev/null
	@diff -w -q $@ $*-output.json || echo "curl $* failed: make sure you have done 'make run'"

%-direct.out : %-input.json
	@docker exec -i basic-reveng /bin/algorun < $< > $@
	@diff -w -q $@ $*-output.json || echo "direct $* failed: make sure you have done 'make run'"

clean:
	rm -rf test/*.out share/ algorun_info/*example.txt
