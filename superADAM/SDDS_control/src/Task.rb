require 'json'
require 'matrix'
require 'pp'

class Model
	def initialize(json)
		@model = json
		@name = @model['name']
		@descripton = @model['description']
		@version = @model['version']
		@raw_output=nil
		@json_output=nil
		@tmp_files=[]
	end

	def get_transitionTable()
		mx=[]
		res=""
		@model['updateRules'].each do |v|
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
		@model['updateRules'].each { |v| res+=v['inputVariables'].length.to_s+" " }
		@model["nv"]=res.split(' ')
		return res
	end

	def get_inputVariables()
		max_rows=0
		mx=[]
		res=""
		@model['updateRules'].each do |v|
			col=[]
			v['inputVariables'].each { |v| col.push(v[1..-1]) }
			if v['inputVariables'].length > max_rows then
				max_rows=v['inputVariables'].length
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

end


class Task
	def initialize(json,exec_file)
		@raw_output=nil
		@json_output=nil
		@model=nil
		@numberOfVariables=nil
		@exec_file=exec_file
		@errors=[]
		@warnings=[]
		@input = {
			"DiscreteDynamicalSystemSet"=>{}
		}
		json.each do |o|
			case o['type'].downcase
			when "discretedynamicalsystemset"
				@input['DiscreteDynamicalSystemSet']=Model.new(o)
			end
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
		@arguments={}
        
        # parse parameter for propensities
        envPropensities = ENV['propensities']
        envPropensities = envPropensities[1,(envPropensities.length-2)]
        propensities = []
        for x in envPropensities.split(',,')
            propensities.push( JSON.parse(x))
        end
        
        # parse parameter for controlNodes
        envControlNodes = ENV['controlNodes']
        envControlNodes = envControlNodes[1,(envControlNodes.length-2)]
        controlNodes = []
        for x in envControlNodes.split(',,')
            controlNodes.push( JSON.parse(x))
        end
        
        # parse parameter for controlEdges
        envControlEdges = ENV['controlEdges']
        envControlEdges = envControlEdges[1,(envControlEdges.length-2)]
        controlEdges = []
        for x in envControlEdges.split(',,')
            controlEdges.push( JSON.parse(x))
        end
        
        # parse parameter for costFunction
        envCostFunction = ENV['costFunction']
        envCostFunction = envCostFunction[1,(envCostFunction.length-2)]
        costFunction = []
        for x in envCostFunction.split(',,')
            costFunction.push( JSON.parse(x))
        end

		@default_values= {
            'propensities'=>propensities,
            'controlNodes'=>controlNodes,
            'controlEdges'=>controlEdges,
			'costFunction'=>costFunction
		}
		super(json,exec_file)
	end

	def validate_input
		@errors.push(:POLYNOMIAL_DYNAMICAL_SYSTEM_TABLE_REQUIRED) if @input['DiscreteDynamicalSystemSet'].nil?
		required=[
			'propensities',
			'controlNodes',
			'controlEdges',
			'costFunction'
		]
		required.each do |arg|
			if @arguments[arg].nil? then
				if not @default_values[arg].nil? then
					@arguments[arg]=@default_values[arg]
				end
			end
		end
	end

	def get_propensity()
		mx=[]
		res=""
		@arguments['propensities'].each do |v|
			col=[v['activation'],v['degradation']]
			mx.push(col)
		end
		mx = Matrix.rows(mx).t().to_a()
		mx.each { |r| res+=r.join(' ')+"\n" }
		return res
	end

	def get_controlNodes()
		mx=[]
		@arguments['controlNodes'].each do |v|
			mx.push(v['nodeIndex'])
		end
		res = mx.join(' ')
		return res
	end

	def get_controlEdges()
		mx=[]
		res=""
		@arguments['controlEdges'].each do |v|
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
		@arguments['costFunction'][0]['value'].each do |v|
			col=[v['nodeIndex'],v['nodeValue'],v['nodeWeight']]
			mx.push(col)
		end
		mx.each { |r| res+=r.join(' ')+"\n" }
		return res
	end

	def run()
		model=@input['DiscreteDynamicalSystemSet']
		File.open('tt.txt','w') { |f| f.write(model.get_transitionTable()) }
		File.open('nv.txt','w') { |f| f.write(model.get_numberOfValues()) }
		File.open('varf.txt','w') { |f| f.write(model.get_inputVariables()) }
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
		res={"ControlPolicy"=>{}}
		lines=@raw_output.split("\n")
		lines.each do |l|
			l.slice! " --->  "
			tmp=l.split(' ')
			res['ControlPolicy'][tmp[0]]=[tmp[1].to_i,tmp[2].to_i]
		end
		#@json_output= JSON.generate(res)
		return res
	end
end

def setEnvVariables()
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
end

if $0 == __FILE__ then
	if !File.exists?(ARGV[0]) then puts "JSON input file not found" end
	path='/home/algorithm/src/SDDS'
	test=false
	if ARGV[1]=='--test' then
		setEnvVariables()
		path='./SDDS'
		test=true
	end
	input = File.read(ARGV[0])
	json = JSON.parse(input)
	task=SDDS.new(json,path)
	task.run()
	if test then
		puts JSON.pretty_generate(task.render_output())
		task.clean_temp_files()
	else
		File.open("output.txt",'w') { |f| f.write(JSON.pretty_generate(task.render_output())) }
	end
end
