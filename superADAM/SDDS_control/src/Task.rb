require 'json'
require 'matrix'
require 'pp'

class TaskMethod
	attr_reader :type, :id, :description, :arguments
	def initialize(method)
		@type=method['type']
		@id=method['id']
		@description=method['desription']
		@arguments={}
		if !method['arguments'].empty? then
			method['arguments'].each do |arg|
				@arguments[arg['name']]=arg['value']
			end
		end
	end
end

class Model
	attr_reader :fieldCardinality, :type, :description, :name, :version, :parameters, :updateRules, :variables, :variableScores, :simlab
	def initialize(model)
		@type=model['type']
		@description=model['description']
		@name=model['name']
		@version=model['version']
		@fieldCardinality=model['fieldCardinality']
		@parameters=model['parameters']
		@updateRules=model['updateRules']
		@variables=model['variables']
		@variableScores=model['variableScores']
		@simlab=model['simlab']
	end
end

class TimeSeries
	attr_reader :data
	def initialize(ts)
		@data=ts['timeSeriesData']
	end

	def get_numberOfVariables()
		if !@data.empty? then
			return @data[0]['matrix'][0].length
		end
		return 0
	end

	def get_wildType()
		wt=[]
		@data.each do |tdata|
			if tdata['index'].empty? then
				wt.push(tdata['matrix'])
			end
		end
		return wt
	end

	def get_knockOut()
		ko=[]
		@data.each do |tdata|
			if !tdata['index'].empty? then
				ko.push([tdata['index'][0],tdata['matrix']])
			end
		end
		return ko
	end
end

class Task
	def initialize(json,exec_file)
		@raw_output=nil
		@json_output=nil
		@numberOfVariables=nil
		@exec_file=exec_file
		@errors=[]
		@warnings=[]
		@task = json['task']
		if @task.nil? then  raise "JSON_FILE_HAS_NO_TASK" end
		if @task['input'].nil? then  raise "TASK_HAS_NO_INPUT" end
		if @task['method'].nil? then  raise "TASK_HAS_NO_METHOD" end
		@method=TaskMethod.new(@task['method'])
		@input = {
			"models"=>{},
			"timeSeries"=>[],
			"custom"=>[]
		}
		@task['input'].each do |o|
			case o['type'].downcase
			when "model"
				@input['models'][o['name']]=Model.new(o)
			when "timeseries"
				@input['timeSeries'].push(TimeSeries.new(o))
			else
				@input['custom'].push(input)
			end
		end
		if !@input['timeSeries'].empty? then
			@numberOfVariables=@input['timeSeries'][0].get_numberOfVariables()
		end
		@tmp_files=[]
		self.validate_input()
		if !@warnings.empty? then @warnings.each {|w| STDERR.puts(w.to_s) } end
		if !@errors.empty? then
			@errors.each {|e| STDERR.puts(e.to_s) } 
			raise "%i INPUT ERRORS FOUND AND %i WARNINGS ISSUED" % [@errors.length, @warnings.length]
		end
	end

	def validate_input
		@errors.push(:INPUT_VALIDATION_NOT_IMPLEMENTED)
	end

	def render_output()
		if @raw_output.nil? then
			puts "No output to render...\n"
			return
		end
		# @json_output= JSON.generate(@raw_output)
		# return @json_output
	end

	def clean_temp_files()
		@tmp_files.each { |f| File.delete(f) }
	end
end

class SDDS<Task
	def initialize(json,exec_file)
		super(json,exec_file)
	end

	def get_transitionTable()
		mx=[]
		res=""
		@model['updateRules'].each do |k,v|
			col=[]
			v['transitionTable'].each { |l| col.push(l.last) }
			mx.push(col)
		end
		mx = Matrix.rows(mx).t().to_a()
		mx.each { |r| res+=r.join(' ')+"\n" }
		return res
	end

	def get_numberOfValues()
		res=""
		@model['updateRules'].each { |k,v| res+=v['possibleInputVariables'].length.to_s+" " }
		@model["nv"]=res.split(' ')
		return res
	end

	def get_inputVariables()
		max_rows=0
		mx=[]
		res=""
		@model['updateRules'].each do |k,v|
			col=[]
			v['possibleInputVariables'].each { |v| col.push(v[1..-1]) }
			if v['possibleInputVariables'].length > max_rows then
				max_rows=v['possibleInputVariables'].length
			end
			mx.push(col)
		end
		mx.each do |l|
			max_rows.times do |i|
				if l[i].nil? then l.push("-1") end
			end
		end
		mx = Matrix.rows(mx).to_a()
		mx.each { |r| res+=r.join(' ')+"\n" }
		@model["varf"]=mx
		return res
	end

	def get_propensity()
		mx=[]
		res=""
		@model['propensities'].each do |k,v|
			col=[v['activation'],v['degradation']]
			mx.push(col)
		end
		mx = Matrix.rows(mx).t().to_a()
		mx.each { |r| res+=r.join(' ')+"\n" }
		return res
	end

	def get_controlNodes()
		mx=[]
		@model['controlNodes'].each do |k,v|
			mx.push(v['nodeIndex'])
		end
		res = mx.join(' ')
		return res
	end

	def get_controlEdges()
		mx=[]
		res=""
		@model['controlEdges'].each do |k,v|
			col=[v['edgeTail'],v['edgeHead']]
			mx.push(col)
		end
		mx = Matrix.rows(mx).t().to_a()
		mx.each { |r| res+=r.join(' ')+"\n" }
		return res
	end

	def get_nodeWeight()
		mx=[]
		res=""
		@model['costFunction']['desiredState'].each do |k,v|
			col=[v['nodeIndex'],v['nodeValue'],v['nodeWeight']]
			mx.push(col)
		end
		mx.each { |r| res+=r.join(' ')+"\n" }
		return res
	end

	def run()
		File.open('tt.txt','w') { |f| f.write(self.get_transitionTable()) }
		File.open('nv.txt','w') { |f| f.write(self.get_numberOfValues()) }
		File.open('varf.txt','w') { |f| f.write(self.get_inputVariables()) }
		File.open('prop.txt','w') { |f| f.write(self.get_propensity()) }
		File.open('cnodes.txt','w') { |f| f.write(self.get_controlNodes()) }
		File.open('cedges.txt','w') { |f| f.write(self.get_controlEdges()) }
		File.open('cost.txt','w') { |f| f.write(self.get_nodeWeight()) }
		@tmp_files.push('tt.txt','nv.txt','varf.txt','prop.txt','cnodes.txt','cedges.txt','cost.txt')
		system(@exec_file+' -tt tt.txt -nv nv.txt -varf varf.txt -prop prop.txt -cnodes cnodes.txt -cedges cedges.txt -cost cost.txt > output.txt')
		@tmp_files.push('output.txt')
		if $?.exitstatus>0 then
			puts "Error: Cannot run algorithm"
		else
			File.open('output.txt') { |f| @raw_output=f.read() }
		end
		return $?.exitstatus
	end

	def render_output()
		if @raw_output.nil? then
			puts "No output to render...\n"
			return
		end
		res=@model
		res["control policy"]={}
		lines=@raw_output.split("\n")
		lines.each do |l|
			l.slice! " --->  "
			tmp=l.split(' ')
			res['control policy'][tmp[0]]=[tmp[1].to_i,tmp[2].to_i]
		end
		@json_output= JSON.generate(res)
		return @json_output
	end

	def clean_temp_files()
		@tmp_files.each { |f| File.delete(f) }
	end
end

class SDDS < Task
	def initialize(json,exec_file)
		super(json,exec_file)
		@file_manager=nil
	end

	def validate_input
		# input must contain a timeseries
		if @input['timeSeries'].empty? then @errors.push(:TIMESERIES_REQUIRED) end
		# input should contain only 1 timeseries
		if @input['timeSeries'].length>1 then @warnings.push(:ONLY_FIRST_TIMESERIES_WILL_BE_TAKEN_INTO_ACCOUNT) end
		# timeseries must contain only binary matrixes
		@input['timeSeries'].each do |ts|
			ts.data.each do |m|
				m['matrix'].each do |r|
					if r.max>1 then @errors.push(:TIMESERIES_MATRIXES_MUST_BE_BINARY) end
				end
				if !m['index'].empty? then
					if m['index'].length>1 then @warnings.push(:ONLY_FIRST_NODE_WILL_BE_KNOCKED_OUT) end
				end
			end
		end
		# timeseries must contain at least 1 wildtype
		wt_found=false
		@input['timeSeries'].each do |ts|
			ts.data.each do |m|
				if m['index'].empty? then wt_found=true end
			end
		end
		if !wt_found then @errors.push(:TIMESERIES_MUST_CONTAIN_AT_LEAST_1_WILDTYPE) end
		# if a model is present, its fieldcardinity must be equal to 2
		if !@input['models'].empty? then
			@input['models'].each do |k,m|
				if m.fieldCardinality!=2 then @errors.push(:MODELS_FIELD_CARDINALITY_MUST_BE_2) end
			end
		end

		# the following arguments are required
		required=[
			'HammingPolyWeight',
			'ComplexityWeight',
			'RevEngWeight',
			'BioProbWeight',
			'HammingModelWeight',
			'PolyScoreWeight',
			'GenePoolSize',
			'NumCandidates',
			'NumParentsToPreserve',
			'MaxGenerations',
			'StableGenerationLimit',
			'MutateProbability'
		]
		required.each do |arg|
			if @method.arguments[arg].nil? then @errors.push(("MISSING_ARGUMENT_ERROR_"+arg.upcase).to_sym) end
		end
	end

	def get_fieldCardinality()
		return "P=2;\n"	
	end

	def get_numberOfVariables()
		return "N=%i;\n" % @numberOfVariables
	end

	def get_wildType()
		res="WT={"
		wt=@input['timeSeries'][0].get_wildType()
		wt_array=[]
		wt.each_with_index do |w,i|
			tmp=""
			w.each { |r| tmp+=r.join(' ')+"\n" }
			File.open("w%i.txt" % i,'w') { |f| f.write(tmp) }
			wt_array.push("\"w%i.txt\"" % i)
			@tmp_files.push("w%i.txt" % i)
		end
		res+=wt_array.join(',').to_s
		res+="};\n"
		return res
	end

	def get_knockOut()
		res="KO={"
		ko=@input['timeSeries'][0].get_knockOut()
		ko_array=[]
		ko.length.times do |i|
			tmp=""
			ko[i][1].each { |r| tmp+=r.join(' ')+"\n" }
			File.open("K%i.txt" % i,'w') { |f| f.write(tmp) }
			ko_array.push("(%i,\"K%i.txt\")" % [ko[i][0], i])
			@tmp_files.push("K%i.txt" % i)
		end
		res+=ko_array.join(',').to_s
		res+="};\n"
		return res
	end

	def get_priorReverseEngineeringNetwork()
		model=@input['models']['priorReverseEngineeringNetwork']
		if !model.nil? then
			res=""
			model.variableScores.each_with_index do |vs,i|
				i_baby=i+1
				res+="F%i " % i_baby
				row=Array.new(@numberOfVariables,0)
				vs['sources'].each do |s|
					idx=s['source'].slice!("x")
					row[idx.to_i]=s['score'].to_f.to_s
				end
				res+=row.join(' ')+" 1\n"	
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
		if !@method.arguments['priorBiologicalNetwork'].nil? then
			res=""
			@method.arguments['priorBiologicalNetwork'].each_with_index do |r,i|
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
		model=@input['models']['priorModel']
		if !model.nil? then
			functions=[]
			combinations=1
			model.updateRules.each do |rule|
				var=[]
				rule['functions'].each { |f| var.push(f['polynomialFunction']) }
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
		res="\nHammingPolyWeight\t"+@method.arguments['HammingPolyWeight'].to_s
		res+="\nComplexityWeight\t"+@method.arguments['ComplexityWeight'].to_s
		res+="\nRevEngWeight\t"+@method.arguments['RevEngWeight'].to_s
		res+="\nBioProbWeight\t"+@method.arguments['BioProbWeight'].to_s
		res+="\nHammingModelWeight\t"+@method.arguments['HammingModelWeight'].to_s
		res+="\nPolyScoreWeight\t"+@method.arguments['PolyScoreWeight'].to_s
		res+="\nGenePoolSize\t"+@method.arguments['GenePoolSize'].to_s
		res+="\nNumCandidates\t"+@method.arguments['NumCandidates'].to_s
		res+="\nNumParentsToPreserve\t"+@method.arguments['NumParentsToPreserve'].to_s
		res+="\nMaxGenerations\t"+@method.arguments['MaxGenerations'].to_s
		res+="\nStableGenerationLimit\t"+@method.arguments['StableGenerationLimit'].to_s
		res+="\nMutateProbability\t"+@method.arguments['MutateProbability'].to_s
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
end

if $0 == __FILE__ then
	if !File.exists?(ARGV[0]) then puts "JSON input file not found" end
	input = File.read(ARGV[0])
	json = JSON.parse(input)
	task=Task.new(json,'.././React')
	task.run()
	puts task.render_output()
	task.clean_temp_files()
end
