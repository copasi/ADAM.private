Directory Structure for Super ADAM
Date: October 21, 2014
-----------------------------------

superadam/
	<module1>/
		doc/
			sample-input.json
			sample-output.json
			doc-input.txt
			doc-output.txt
			doc-module.txt
		test/
			<test1>-input.json
			<test2>-output.json
			...
		src/
			source code
			m2 code
			c++ code
			perl code
			ruby code
			makefiles

	share/
		code to be shared between modules
	bin/
		executables
	lib/
		only stefan will can put files here
		install files

seda: 	randomsampling
	SDDS
david:	SDDS-control
elena:	lib/M2Code/ReverseEngineering
paola: 	REACT

