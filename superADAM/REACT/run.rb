#!/usr/bin/ruby
require './algorun/Task.rb'
param=ARGV[0]
if param.nil? then param="help" end
case param
	when "help"
		puts "REACT Evolutionary Algorithm for Discrete Dynamical System Optimization" 
		puts ""
		puts "Usage: ./run.rb [help|make|check|<input_file.json>]"
		puts ""
		puts "* make: compile REACT"
		puts "* check: run json tests file against REACT"
		puts "* <input_file.json>: run REACT with the input JSON file"
		puts "* clean: remove temporary and compiled files"
		puts "* help: shows this help message"
	when "make"
		Dir.chdir "src"
		system("make")
		system("cp React ..")
	when "check"
		input = File.read("test/test1/REACT_Input Example1.json")
		test1 = JSON.parse(input)
		input = File.read("test/test2/REACT_InputExample2.json")
		test2 = JSON.parse(input)
		input = File.read("test/test3/REACT_Input Example3.json")
		test3 = JSON.parse(input)
		begin
			puts "============== TEST1/3 ==============="
			task1=React.new(test1,'./React')
			task1.run()
			task1.render_output()
			task1.clean_temp_files()
			puts "============== TEST2/3 ==============="
			task2=React.new(test2,'./React')
			task2.run()
			task2.render_output()
			task2.clean_temp_files()
			puts "============== TEST3/3 ==============="
			task3=React.new(test3,'./React')
			task3.run()
			task3.render_output()
			task3.clean_temp_files()
		rescue StandardError=>e
			STDERR.puts "ERROR: "+e.to_s
		end

		# run tests here
	when "clean"
		system("rm Bio.txt K*.txt output.txt RevMat.txt params.txt w*.txt Model*.txt fileman.txt")
		File.delete("React") if File.exists?("React")
		Dir.chdir "src"
		system("make clean")
	else
		if !File.exists?(param) or File.directory?(param) then
			puts ("ERROR: No valid JSON input file given")
		else
			input = File.read(param)
			json = JSON.parse(input)
			begin
				task=React.new(json,'./React')
				task.run("output.txt")
				pp task.render_output("output.txt")
				task.clean_temp_files()
			rescue StandardError=>e
				STDERR.puts "ERROR: "+e.to_s
			end
		end
end
