require 'json'

class BNReduction	
	def initialize(json)
		@ks = Hash.new	
		@xs = Hash.new	
		@steadystates = Hash.new
		@parameters = []
		@idorder = []
		@value = []
		@json_data = json
		self.j2i_parse_json()
	end

	def j2i_parse_json()
		@parsed = JSON.parse(@json_data)
		@karguments =  @parsed["task"]["method"]["arguments"]
		@model_type = @parsed["task"]["input"][0]["type"]
		@model_description = @parsed["task"]["input"][0]["description"]
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

	def j2i_get_input()
		@formatted_input = ''
		i = 1
		while i <= @xs.length do
			index = "x" + String(i)
			@formatted_input += j2i_replace_k(@xs[index])
			@formatted_input += "\n"
			i = i + 1
		end
		i = 1
		while i <= @ks.length
			index = "k" + String(i)
			@formatted_input += String(@ks[index])
			@formatted_input += "\n"
			i = i + 1
		end
		return @formatted_input
	end

	def j2i_replace_k(k_string)
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

	def o2j_read_file(output_file)
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
		@steadystates["value"] = @value
		@final = Hash.new
		@output = Hash.new
		@output["type"] = @model_type
		@output["description"] = @model_description
		@output["parameters"] = @parsed["task"]["input"][0]["parameters"]
		@output["updateRules"] = @parsed["task"]["input"][0]["updateRules"]
		@output["variables"] = @parsed["task"]["input"][0]["variables"]
		@output["steadystates"] = @steadystates
		@final["output"] = [@output]
		@final_json = JSON.pretty_generate(@final)
	end
	
	def get_final_json()
		return @final_json
	end

	def run()
		# main_dir = File.expand_path("..", Dir.pwd)
		# Dir.chdir ENV["CODE_HOME"] + "src/"

		@in = j2i_get_input()
		@bnr_input_file = "bnr_input.txt"
		f = File.open(@bnr_input_file, "w")
		f.write(@in)
		f.close()
		system("./BNReduction.sh"+' '+@bnr_input_file)
		
		@bnr_output_file = "bnr_input.txt.fp"
		o2j_read_file(@bnr_output_file)
		return get_final_json()
	end
end

input_file = ARGV[0].dup
f = File.open(input_file)
js = ''
f.each_line do |line|
	js += line
end
f.close()
ex_file = ''
@test = BNReduction.new(js)
result = @test.run()
f = File.open("output.txt", "w")
f.write(result)
f.close()
