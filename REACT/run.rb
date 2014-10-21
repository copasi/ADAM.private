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
		puts "* help: shows this help message"
		puts "* make: compile REACT"
		puts "* check: run tests file against REACT"
		puts "* <input_file.json>: run REACT with the input JSON file"
	when "make"
		system("make")
	when "check"
		# run tests here
	else
		if !File.exists?(param)	then puts "JSON input file not found" end
		input = File.read(param)
		json = JSON.parse(input)
		task=Task.new(json,'./React')
		task.run()
		puts task.render_output()
		task.clean_temp_files()
end
