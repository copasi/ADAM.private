require 'json'
require 'matrix'

class Model
	def initialize(json,exec_file)
		@model = json['model']
		@name = @model['name']
		@descripton = @model['description']
		@version = @model['version']
		@raw_output=nil
		@json_output=nil
		@tmp_files=[]
		@exec_file=exec_file
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
		mx = Matrix.rows(mx).t().to_a()
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
