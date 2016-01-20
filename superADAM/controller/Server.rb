#!/usr/bin/env ruby

require 'webrick'
require 'open-uri'
require 'json'
require 'net/http'

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

    def do_POST (request, response)
	output = "Internal Server Error!"
	response.status = 500
	case request.path
		when "/do/run"	
			user_input = request.query["input"]
			if request.query["callback"].nil? then
				output = "No callback provided. Request not passed!"
			else
				f = File.open('callback.txt', "w")
				f.write(request.query["callback"])
				f.close()
				if not ENV["OUTPUT_TO"].nil? then
					output_to=eval(ENV["OUTPUT_TO"])
					output_to.each do |node|
						eval("def check(json)\n"+node["condition"]+"\nend\n")
						if check(user_input) then
							res = Net::HTTP.post_form(URI(node["target"]),'input'=>user_input)
							output = "Request passed to the first module successfully ..\n"
							output += "Now, listen to your callback URL!"
							response.status = 200
						end
					end
				else
					output = "Couldn't pass input to first module in the workflow!"
				end
			end
		when "/do/done"
			final_output = request.query["input"]
			if File.file?('callback.txt') then
				f = File.open('callback.txt')
				callback = f.gets
				f.close()
				res = Net::HTTP.post_form(URI(callback),'input'=>final_output)
				output = "Thank you last module for completing the job!"
				response.status = 200
				File.delete('callback.txt')
			else
				output = "No task provided first with callback!"
			end	
		else
			output = "Path request not found!"
			response.status = 404
	end
	response.content_type = "application/json"
	response.body = output + "\n"
    end
end

if $0 == __FILE__ then
	server = WEBrick::HTTPServer.new(:Port => 8765, "RequestTimeout" => 3000)#, :DocumentRoot => "web/")
	server.mount("/do", Algorun)
	trap("INT") {
		server.shutdown
	}
	server.start()
end
