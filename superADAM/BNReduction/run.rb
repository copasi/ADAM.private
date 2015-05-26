#!/usr/bin/ruby
require_relative './algorun/Task.rb'
require_relative './algorun/BNReduction.rb'
require_relative './algorun/Server.rb'

if ENV["CODE_HOME"].nil? then
	ENV["CODE_HOME"]=ENV["PWD"]
end

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

def run_test(num)
	input = File.read("test/test"+num+"/BNReduction_Input_Example"+num+".json")
	test = JSON.parse(input)
	output_ref = File.read("test/test"+num+"/BNReduction_Output_Reference"+num+".json")
	test_reference_output = JSON.parse(output_ref)
	puts "============== TEST"+num+"/3 ==============="
	task = BNReduction.new(json)
	task.run()
	output = task.get_final_json()
	puts output
	#task.clean_temp_files()
	if task.test(test_reference_output) then
		return "TEST "+num+" PASSED".green()
	else
		return "TEST "+num+" FAILED".red()
	end
end

param=ARGV[0]
if param.nil? then param="help" end
case param
	when "help"
		puts "BNReduction algorithm" 
		puts ""
		puts "Usage: ./run.rb [help|make|check|<input_file.json>]"
		puts ""
		puts "* make: compile BNReduction"
		puts "* check: run all json tests file against Reduction and compares them to reference output files"
		puts "* test <test_number>: run test #<test_number>"
		puts "* <input_file.json>: run BNReduction with the input JSON file"
		puts "* clean: remove temporary and compiled files"
		puts "* start: start the BNReduction web service"
		puts "* help: shows this help message"
	when "make"
		Dir.chdir ENV['CODE_HOME']+"/src"
		system("make")
		system("cp BNReduction ..")
	when "test"
		num=ARGV[1]
		if not ["1","2","3"].include? num then
			puts "Test number does not exist. Please choose a number between 1 and 3."
			exit
	       	end
		begin
			puts run_test(num)
		rescue StandardError=>e
			STDERR.puts "ERROR: "+e.to_s
		end
	when "check"
		tests=[]
		begin
			["1","2","3"].each do |i|
				tests.push(run_test(i))
				puts tests.last
			end
			tests.each { |p| puts p }
		rescue StandardError=>e
			STDERR.puts "ERROR: "+e.to_s
		end
	when "clean"
		system("rm Bio.txt K*.txt output.txt RevMat.txt params.txt w*.txt Model*.txt fileman.txt")
		File.delete("BNReduction") if File.exists?("BNReduction")
		Dir.chdir "src"
		system("make clean")
	when "start"
		server = WEBrick::HTTPServer.new(:Port => 8765, "RequestTimeout" => 300, :DocumentRoot => ENV["CODE_HOME"]+"algorun/web/")
		server.mount("/do", Algorun)
		trap("INT") {
			server.shutdown
		}
		server.start()
	else
		if !File.exists?(param) or File.directory?(param) then
			puts ("ERROR: No valid JSON input file given")
		else
			input = File.read(param)
			json = JSON.parse(input)
			begin
				task.run()
				output = task.get_final_json()
				puts output
				task.clean_temp_files()
			rescue StandardError=>e
				STDERR.puts "ERROR: "+e.to_s
			end
		end
end
