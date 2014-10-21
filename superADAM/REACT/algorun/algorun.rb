#!/usr/bin/env ruby

require 'webrick'
require 'open-uri'
require 'json'
require 'pp'
require 'zlib'
require 'base64'

=begin
    WEBrick is a Ruby library that makes it easy to build an HTTP server with Ruby. 
    It comes with most installations of Ruby by default (itâ€™s part of the standard library), 
    so you can usually create a basic web/HTTP server with only several lines of code.
    
    The following code creates a generic WEBrick server on the local machine on port 1234, 
    shuts the server down if the process is interrupted (often done with Ctrl+C).

    This example lets you call the URL's: "add" and "subtract" and pass through arguments to them

    Example usage: 
        http://localhost:1234/run [POST with an input=<json> param]
=end

class AlgoRun
	def initialize (json)
		pp json
		@json = json
		@input = JSON.parse(@json)
		@err=[]
	end

	def zip_data (data)
		data_zip = Zlib::Deflate.deflate(Marshal.dump(data))
		return Base64.encode64 data_zip
	end

	def unzip_data (data_zip)
		return Marshal.load(Zlib::Inflate.inflate(Base64.decode64(data_zip)))
	end

	# parse the input JSON and prepare all params so that the main program can be executed
	def prepare
		puts "AlgoRun.prepare not implemented"
	end	

	# execute the main program
	def run
		puts "AlgoRun.run not implemented"
	end

	# transform the output of the main program to render it as JSON structure	
	def render_output
		puts "AlgoRun.run not implemented"
	end
end

class React < AlgoRun
	def prepare
		output=""
		# fetching P value
		unless (p=@json['P']).nil?
			output+="P=%s\n" % p
		else
			@err.push("Error: missing P value")
		end

		# fetching N value
		unless (n=@json['N']).nil?
			output+="N=%s\n" % n
		else
			@err.push("Error: missing N value")
		end
	end	

	def run
		return system('ps > toto.txt')
	end

	def render_output
		File.open('toto.txt','r') do |f|
			return f.read()
		end
	end
end

class MyServlet < WEBrick::HTTPServlet::AbstractServlet
    def do_GET (request, response)
	response.status = 500
	response.content_type = "text/plain"
	response.body = "get lost\n"
    end

    def do_POST (request, response)
	output=""
	case request.path
		when "/run"
			react = React.new(request.query["input"])
			react.prepare()
			response.status = 500
			if react.run() then
				response.status = 200
			end
			output = react.render_output()
		else
			output+="failure"
			response.status = 404
	end
	response.content_type = "text/plain"
	response.body = output+ "\n"
    end
end

server = WEBrick::HTTPServer.new(:Port => 1234)
server.mount "/", MyServlet
trap("INT") {
    server.shutdown
}
server.start
