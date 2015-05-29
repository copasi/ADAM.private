#!/usr/bin/env ruby

require 'webrick'
require 'open-uri'
require 'json'
require 'net/http'

ADAM_ROOT="/home/democratech/ADAM.private/"

=begin
    WEBrick is a Ruby library that makes it easy to build an HTTP server with Ruby. 
    It comes with most installations of Ruby by default (it's part of the standard library), 
    so you can usually create a basic web/HTTP server with only several lines of code.
    
    The following code creates a generic WEBrick server on the local machine on port 1234, 
    shuts the server down if the process is interrupted (often done with Ctrl+C).

    This example lets you call the URL's: "add" and "subtract" and pass through arguments to them

    Example usage: 
        http://localhost:1234/run [POST with an input=<json> param]
=end

class Algorun < WEBrick::HTTPServlet::AbstractServlet

    def do_GET (request, response)
	output=""
	case request.path
		when "/do/ok"
			@@status="done"
			puts "status: done"
			response.status = 200	
		else
			output+="failure"
			response.status = 404
	end
	response.content_type = "application/json"
	response.body = output+ "\n"
    end

    def do_POST (request, response)
	output=""
	case request.path
		when "/do/run"
			#@@status="waiting"
			#puts "status: waiting"	
			puts request.query
			puts "workflow: "+request.query["workflow"]
			puts "input: "+request.query["input"]
			@@status="done"
			puts "status: done"
			sleep(2)	
			response.status = 500
			while @@status == "waiting" do
				print "."
				sleep(1)
			end
			if @@status=="done" then
				puts "OK"
				output = File.read(ADAM_ROOT+"superADAM/SDDS/test/test1/sample-output.json")
				response.status=200
			else
				puts "KO"
			end
		else
			output+="failure"
			response.status = 404
	end
	response.content_type = "application/json"
	response['Access-Control-Allow-Origin']='http://plantsimlab.local.org'
	response.body = output+ "\n"
    end
end

if $0 == __FILE__ then
	server = WEBrick::HTTPServer.new(:Port => 8880, "RequestTimeout" => 3000, :DocumentRoot => "web/")
	server.mount("/do", Algorun)
	trap("INT") {
		server.shutdown
	}
	server.start()
end
