#!/usr/bin/ruby
require './algorun/Task.rb'

class String
	# colorization
	def colorize(color_code)
		"\e[#{color_code}m#{self}\e[0m"
	end

	def red
		colorize(31)
	end

	def green
		colorize(32)
	end

	def yellow
		colorize(33)
	end

	def pink
		colorize(35)
	end
end

param=ARGV[0]
if param.nil? then param="help" end
case param
	when "help"
		puts "REACT Evolutionary Algorithm for Discrete Dynamical System Optimization" 
		puts ""
		puts "Usage: ./run.rb [help|make|check|<input_file.json>]"
		puts ""
		puts "* make: compile REACT"
		puts "* check: run all json tests file against REACT and compares them to reference output files"
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
		output_ref = File.read("test/test1/REACT_Output_Reference1.json")
		test1_reference_output = JSON.parse(output_ref)
		output_ref = File.read("test/test2/REACT_Output_Reference2.json")
		test2_reference_output = JSON.parse(output_ref)
		output_ref = File.read("test/test3/REACT_Output_Reference3.json")
		test3_reference_output = JSON.parse(output_ref)
		tests=[]
		begin
			puts "============== TEST1/3 ==============="
			task1=React.new(test1,'./React')
			task1.run('output.txt',:test)
			pp task1.render_output('output.txt')
			if task1.test(test1_reference_output) then
				tests.push("TEST 1 PASSED".green())
			else
				tests.push("TEST 1 FAILED".red())
			end
			task1.clean_temp_files()
			puts tests.last
			puts "============== TEST2/3 ==============="
			task2=React.new(test2,'./React')
			task2.run('output.txt',:test)
			pp task2.render_output('output.txt')
			if task2.test(test2_reference_output) then
				tests.push("TEST 2 PASSED".green())
			else
				tests.push("TEST 2 FAILED".red())
			end
			puts tests.last
			task2.clean_temp_files()
			puts "============== TEST3/3 ==============="
			task3=React.new(test3,'./React')
			task3.run('output.txt',:test)
			pp task3.render_output('output.txt')
			if task3.test(test3_reference_output) then
				tests.push("TEST 3 PASSED".green())
			else
				tests.push("TEST 3 FAILED".red())
			end
			task3.clean_temp_files()
			tests.each { |p| puts p }
		rescue StandardError=>e
			STDERR.puts "ERROR: "+e.to_s
		end
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
				puts JSON.dump(task.render_output("output.txt"))
				task.clean_temp_files()
			rescue StandardError=>e
				STDERR.puts "ERROR: "+e.to_s
			end
		end
end
