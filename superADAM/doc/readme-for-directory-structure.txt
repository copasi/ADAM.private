Directory Structure for Super ADAM
Date: October 21, 2014
-----------------------------------------------------------------
Below is the directory structure for superADAM, including the structure for subfolders.
Strings in < > or with spaces are open to any naming convention.   
Other folder and filenames (in format string.ext) are fixed. 
-----------------------------------------------------------------

superadam/
	share/
		<code to be shared between modules>
	bin/
		<executables>
	lib/
		<only stefan will can put files here see example below>
		install files
	<moduleName>/
		doc/
			sample-input.json
			sample-output.json
			doc-input.txt
			doc-output.txt
			doc-module.txt
		test/
			<test1>-input.json
			<test1>-output.json
			<test2>-input.json
			<test2>-output.json
			...
		src/
			<source code - see examples below>
			m2 code
			c++ code
			perl code
			ruby code
			makefiles
