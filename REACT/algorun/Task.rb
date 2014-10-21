require 'json'
require 'matrix'
require 'pp'

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
			ko_array.push("(%i,\"K%i.txt\")" % [ko[i][0], i])
			@tmp_files.push("K%i.txt" % i)
		end
		res+=ko_array.join(',').to_s
		res+="};\n"
		return res
	end

	def get_priorReverseEngineeringNetwork()
		if !@method['parameters']['priorReverseEngineeringNetwork'].empty? then
			res=""
			@method['parameters']['priorReverseEngineeringNetwork'].each_with_index do |r,i|
				idx=i+1
				res+="F%i " % idx
				res+=r.join(' ')+"\n"
			end
			File.open('RevMat.txt','w') { |f| f.write(res) }
			@tmp_files.push("RevMat.txt")
			return "REV={\"RevMat.txt\"};\n"
		else
			return "REV={};\n"
		end
	end

	def get_complexity()
		# not supported by REACT at this time
		return "CMPLX={};\n"
	end

	def get_priorBiologicalNetwork()
		if !@method['parameters']['priorBiologicalNetwork'].empty? then
			res=""
			@method['parameters']['priorBiologicalNetwork'].each_with_index do |r,i|
				idx=i+1
				res+="F%i " % idx
				res+=r.join(' ')+"\n"
			end
			File.open("Bio.txt",'w') { |f| f.write(res) }
			@tmp_files.push("Bio.txt")
			return "BIO={\"Bio.txt\"};\n"
		else
			return "BIO={};\n"
		end
	end

	def get_priorModel()
		res="MODEL={"
		if !@method['parameters']['updateRules'].empty? then
			functions=[]
			combinations=1
			@method['parameters']['updateRules'].each do |k,v|
				var=[]
				v.each { |f| var.push(f['polynomialFunction']) }
				functions.push(var)
				combinations*=var.length
			end
			mx=[]
			functions.each do |f|
				mx.push(f*(combinations/f.length))
			end
			models=Matrix.rows(mx).t().to_a()
			models.each_with_index do |m,i|
				tmp=""
				m.each_with_index { |f,j| tmp+="f%i=%s\n" % [j+1,f] }
				File.open("Model%i.txt" % i,'w') { |f| f.write(tmp) }
				@tmp_files.push("Model%i.txt" % i)
			end
			str=[]
			combinations.times do |i|
				str.push("\"Model%i.txt\"" % i)
			end
			res+=str.join(',')
		end
		res+="};\n"
		return res
	end

	def get_parameters()
		basic=@method['parameters']['EAparams']['basicparams']
		advanced=@method['parameters']['EAparams']['advancedparams']
		if !basic['HammingPolyWeight'].nil? then res="\nHammingPolyWeight\t"+basic['HammingPolyWeight'].to_s end
		if !basic['ComplexityWeight'].nil? then res="\nComplexityWeight\t"+basic['ComplexityWeight'].to_s end
		if !basic['RevEnvWeight'].nil? then res+="\nRevEngWeight\t"+basic['RevEnvWeight'].to_s end
		if !basic['BioProbWeight'].nil? then res+="\nBioProbWeight\t"+basic['BioProbWeight'].to_s end
		if !basic['HammingModelWeight'].nil? then res+="\nHammingModelWeight\t"+basic['HammingModelWeight'].to_s end
		if !basic['PolyScoreWeight'].nil? then res+="\nPolyScoreWeight\t"+basic['PolyScoreWeight'].to_s end
		if !advanced['GenePoolSize'].nil? then res+="\nGenePoolSize\t"+advanced['GenePoolSize'].to_s end
		if !advanced['NumCandidates'].nil? then res+="\nNumCandidates\t"+advanced['NumCandidates'].to_s end
		if !advanced['NumParentsToPreserve'].nil? then res+="\nNumParentsToPreserve\t"+advanced['NumParentsToPreserve'].to_s end
		if !advanced['MaxGenerations'].nil? then res+="\nMaxGenerations\t"+advanced['MaxGenerations'].to_s end
		if !advanced['StableGenerationLimit'].nil? then res+="\nStableGenerationLimit\t"+advanced['StableGenerationLimit'].to_s end
		if !advanced['MutateProbability'].nil? then res+="\nMutateProbability\t"+advanced['MutateProbability'].to_s end
		res+="\n"
		File.open("params.txt",'w') { |f| f.write(res) }
		@tmp_files.push("params.txt")
		return "PARAMS={\"params.txt\"};\n"
	end

	def create_fileManager(file_manager)
		out=""
		begin
			out+=self.get_fieldCardinality()
			out+=self.get_numberOfVariables()
			out+=self.get_wildType()
			out+=self.get_knockOut()
			out+=self.get_priorReverseEngineeringNetwork()
			out+=self.get_priorBiologicalNetwork()
			out+=self.get_priorModel()
			out+=self.get_parameters()
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
			if $?.exitstatus>0 or !File.exists?('output.txt') then
				puts "Error: error occured while trying to run algorithm"
				return 1
			else
				File.open('output.txt','r') { |f| @raw_output=f.read() }
			end
			return 0
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
