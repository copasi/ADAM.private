require 'json'
require 'matrix'

class Task
	def initialize(json,exec_file)
		@task = json['task']
		@type = @task['type']
		@input = @task['input']
		@method = @task['method']
		@file_manager=nil
		@raw_output=nil
		@json_output=nil
		@exec_file=exec_file
		@tmp_files=[]
	end

	def get_fieldCardinality()
		return "P=%i;\n" % @input['reverseEngineeringInputData']['fieldCardinality']
	end

	def get_numberOfVariables()
		return "N=%i;\n" % @input['reverseEngineeringInputData']['numberVariables']
	end

	def get_wildType()
		wt=[]
		res="WT={"
		@input['reverseEngineeringInputData']['timeSeriesData'].each do |tdata|
			if tdata['index'].empty? then
				wt.push(tdata['matrix'])
			end
		end
		wt_array=[]
		wt.each_with_index do |w,i|
			tmp=""
			w.each { |r| tmp+=r.join(' ')+"\n" }
			w.each do |r|
				if r.max>1 then
					raise "WILDTYPE_NOT_BOOLEAN_ERROR"
				end
			end
			File.open("w%i.txt" % i,'w') { |f| f.write(tmp) }
			wt_array.push("\"w%i.txt\"" % i)
			@tmp_files.push("w%i.txt" % i)
		end
		res+=wt_array.join(',').to_s
		res+="};\n"
		return res
	end

	def get_knockOut()
		ko=[]
		res="KO={"
		@input['reverseEngineeringInputData']['timeSeriesData'].each do |tdata|
			if !tdata['index'].empty? then
				ko.push([tdata['index'][0],tdata['matrix']])
				if tdata['index'].length>1 then
					STDERR.puts "Warning: only 1 node can be knocked out at a time. Only first node will be taken into account."
				end
			end
		end
		ko_array=[]
		ko.length.times do |i|
			tmp=""
			ko[i][1].each { |r| tmp+=r.join(' ')+"\n" }
			ko[i][1].each do |r|
				if r.max>1 then
					raise "KNOCKOUT_NOT_BOOLEAN_ERROR"
				end
			end
			File.open("K%i.txt" % i,'w') { |f| f.write(tmp) }
			ko_array.push("(%i, \"K%i.txt\")" % [ko[i][0], i])
			@tmp_files.push("K%i.txt" % i)
		end
		res+=ko_array.join(',').to_s
		res+="};\n"
		return res
	end

	def get_reverseEngineering()
	end

	def get_complexity()
	end

	def get_priorBioInfo()
	end

	def get_priorModel()
	end

	def get_parameters()
	end

	def create_fileManager(file_manager)
		out=""
		begin
			out+=self.get_fieldCardinality()
			out+=self.get_numberOfVariables()
			out+=self.get_wildType()
			out+=self.get_knockOut()
		rescue StandardError=>err
			STDERR.puts err
			return false
		end
		File.open(file_manager,'w') { |f| f.write(out) }
		@tmp_files.push(file_manager)
		@file_manager=file_manager
		return true
	end

	def run()
		if self.create_fileManager("fileman.txt") then
			system(@exec_file+' '+@file_manager+' output.txt')
			if $?.exitstatus>0 then
				puts "Error: Cannot run algorithm"
			else
				File.open('output.txt') { |f| @raw_output=f.read() }
			end
			return $?.exitstatus
		end
	end

	def render_output()
		if @raw_output.nil? then
			puts "No output to render...\n"
			return
		end
		return @raw_output
		#@json_output= JSON.generate(res)
		#return @json_output
	end

	def clean_temp_files()
		@tmp_files.each { |f| File.delete(f) }
	end
end
