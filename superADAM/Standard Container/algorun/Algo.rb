class Algo
	
	def initialize(input)
		@input_data = input
	end

	def run()
		Dir.chdir ENV["CODE_HOME"] + "src/"
		@input_file = "input.txt"
		fw = File.open(@input_file, "w")
		fw.write(@input_data)
		fw.close()
		
		@command = ''
		if not ENV["EXEC_COMMAND"].nil? then
			@command = ENV["EXEC_COMMAND"]
			@command = @command.strip
		end
		@command_options = ''
		if not ENV["COMMAND_OPTIONS"].nil? then
			@command_options = ENV["COMMAND_OPTIONS"]
			@command_options = " " + @command_options.strip
		end
		if not ENV["OUTPUT_FILE_NAME"].nil? then
			@output_file = ENV["OUTPUT_FILE_NAME"]
			@output_file = @output_file.strip
			system(@command + " " + @input_file + @command_options)
		else
			@output_file = "output.txt"
			system(@command + " " + @input_file + @command_options + " -f " + @output_file)		
		end
		
		@result = ''
		fr = File.open(@output_file, "r")
		fr.each_line do |line|
			@result += line
		end

		fr.close()
		
		return @result
	end
end
