#!/usr/bin/ruby
require_relative 'Task.rb'
require 'pp'

ENV['propensities']=<<END
[
    {
      "activation": 0.9,
      "degradation": 0.9,
      "name": "x1"
    },
    {
      "activation": 0.9,
      "degradation": 0.9,
      "name": "x2"
    },
    {
      "activation": 0.9,
      "degradation": 0.9,
      "name": "x3"
    }
]
END

ENV['controlNodes']=<<END
[
    {
      "name": "n1",
      "nodeIndex": 1,
      "nodeValue": 0
    }
]
END

ENV['controlEdges']=<<END
[
    {
      "edgeHead": 3,
      "edgeTail": 2,
      "edgeValue": 0,
      "name": "e1"
    }
]
END

ENV['costFunction']=<<END
[
    {
      "name": "desiredState",
      "value": [
	  {
	    "name": "x1",
	    "nodeIndex": 1,
	    "nodeValue": 0,
	    "nodeWeight": 1
	  },
	  {
	    "name": "x2",
	    "nodeIndex": 2,
	    "nodeValue": 0,
	    "nodeWeight": 1
	  },
	  {
	    "name": "x3",
	    "nodeIndex": 3,
	    "nodeValue": 0,
	    "nodeWeight": 1
	  }
	]
    }
]
END

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
			puts task1.render_output()
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
				puts JSON.pretty_generate(task.render_output())
				task.clean_temp_files()
			rescue StandardError=>e
				STDERR.puts "ERROR: "+e.to_s
			end
		end
end
