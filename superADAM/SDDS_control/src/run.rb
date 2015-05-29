#!/usr/bin/ruby
require './Task.rb'
param=ARGV[0]
if param.nil? then param="help" end
case param
	when "help"
		puts "SDDS Control - Stochastic Discrete Dynamical Systems" 
		puts ""
		puts "Usage: ./run.rb [help|make|check|<input_file.json>]"
		puts ""
		puts "* make: compile SDDS control"
		puts "* check: run json tests file against SDDS control"
		puts "* <input_file.json>: run SDDS with the input JSON file"
		puts "* clean: remove temporary and compiled files"
		puts "* help: shows this help message"
	when "make"
		system("make")
	when "check"
		input = File.read("../test/input_small_ex.json")
		test1 = JSON.parse(input)
		begin
			puts "============== TEST1/1 ==============="
			task1=SDDS.new(test1,'./SDDS')
			task1.run()
			task1.render_output()
			task1.clean_temp_files()
		rescue StandardError=>e
			STDERR.puts "ERROR: "+e.to_s
		end

		# run tests here
	when "clean"
		# system("rm Bio.txt K*.txt output.txt RevMat.txt params.txt w*.txt Model*.txt fileman.txt")
		File.delete("SDDS") if File.exists?("SDDS")
		system("make clean")
	else
		if !File.exists?(param) or File.directory?(param) then
			puts ("ERROR: No valid JSON input file given")
		else
			input = File.read(param)
			json = JSON.parse(input)
			begin
				task=SDDS.new(json,'./SDDS')
				task.run()
				task.render_output()
				task.clean_temp_files()
			rescue StandardError=>e
				STDERR.puts "ERROR: "+e.to_s
			end
		end
end
