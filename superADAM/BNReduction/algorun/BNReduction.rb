require 'json'

class BNReduction	
	
	def initialize()
		@ks = Hash.new	
		@xs = Hash.new	
		@steadystates = Hash.new
		@parameters = []
		@idorder = []
		@value = []	
	end

	def i2j_readFile(json_file)
		@json_data = ''
		f = File.open(json_file, "r")
		f.each_line do |line|
  			@json_data += line
		end
		f.close	
	end

	def i2j_parse_json()
		@parsed = JSON.parse(@json_data)
		@karguments =  @parsed["task"]["method"]["arguments"]
		ks_length =  @karguments.length
		i = 1
		while i <= ks_length do
			@ks[@karguments[i-1]["id"]] = @karguments[i-1]["value"]
			i = i + 1
		end
		@x_variables = @parsed["task"]["input"][0]["updateRules"]
		xs_length = @x_variables.length
		i = 1
		while i<= xs_length do
			@xs[@x_variables[i-1]["target"]] = @x_variables[i-1]["functions"][0]["booleanFunction"]
			i = i + 1
		end
	end
	
	def i2j_replace_k(k_string)
		occurences = k_string.scan(/k[1-9]/)
		i = 1
		while i <= occurences.length
			n = occurences[i-1].scan(/[1-9]/)
			n = Integer(@xs.length) + Integer(n[0])
			k_string[occurences[i-1]] = "x" + String(n)
			i = i+1	
		end
		return k_string
		
	end
	def i2j_write_output(output_file)
		f = File.open(output_file, "w")
		i = 1
		while i <= @xs.length do
			index = "x" + String(i)
			f.write(replace_k(@xs[index]))
			f.write("\n")
			i = i + 1
		end
		i = 1
		while i <= @ks.length
			index = "k" + String(i)
			f.write(@ks[index])
			f.write("\n")
			i = i + 1
		end
		f.close()
		puts "Done!"
	end
	def j2o_readFile(output_file)
		i = 0

		while i < @ks.length do
			@param = Hash.new
			@param["id"] = @ks.keys[i]
			@param["value"] = @ks.values[i]
			@parameters[i] = @param
			i = i + 1
		end
		@steadystates["parameters"] = @parameters
		i = 0

		while i < @xs.length do
			@idorder[i] = "x" + String(i+1)
			i = i + 1
		end
		@steadystates["idorder"] = @idorder
		i = 0
		f = File.open(output_file, "r") 
		f.each_line do |line|
			j = 0
			@state = []
			while j < @xs.length
				@state[j] = line[j]
				j = j + 1
			end
			@value[i] = @state
			i = i + 1
		end
		#puts @value
		@steadystates["value"] = @value
		@final = Hash.new
		@output = Hash.new
		@output["type"] = "model"
		@output["description"] = "sample model"
		@output["parameters"] = @parsed["task"]["input"][0]["parameters"]
		@output["updateRules"] = @parsed["task"]["input"][0]["updateRules"]
		@output["variables"] = @parsed["task"]["input"][0]["variables"]
		@output["steadystates"] = @steadystates
		@final["output"] = [@output]
		@final_json = JSON.generate(@final)
	end
	
	def j2o_write_output(output_file)
		f = File.open(output_file, "w")
		f.write(@final_json)
		f.close()
		puts 'Done!'
	end
end

if $0 == __FILE__ then
	if !File.exists?(ARGV[0]) then puts "JSON input file not found" end
	
	testObj = BNReduction.new()
	testObj.i2j_readFile(ARGV[0])
	testObj.i2j_parse_json()
	testObj.i2j_write_output('output.txt')

	# testObj.j2o_readFile('algorithm_output.txt')
	# testObj.j2o_write_output('final_output.json')
end


