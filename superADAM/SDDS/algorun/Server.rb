#!/usr/bin/env ruby

require 'webrick'
require 'open-uri'
require 'json'
require 'net/http'

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

class Algorun < WEBrick::HTTPServlet::AbstractServlet

    def do_POST (request, response)
	output=""
	case request.path
		when "/do/run"
			response.status = 500
			json = JSON.parse(request.query["input"])
			begin
				output_file=ENV["CODE_HOME"]+"/output.json"
				task=Sdds.new(json,ENV["CODE_HOME"]+'/src/SDDS.pl')
				task.run(output_file)
				output = JSON.dump(task.render_output(output_file))
				task.clean_temp_files()
				if not ENV["OUTPUT_TO"].nil? then
					output_to=eval(ENV["OUTPUT_TO"])
					output_to.each do |node|
						eval("def check(json)\n"+node["condition"]+"\nend\n")
						if check(output) then
							Net::HTTP.post_form(URI(node["target"]),'input'=>output)
							puts output
						end
					end
				end
				response.status = 200
			rescue StandardError=>e
				output = "ERROR: " + e.to_s
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
	server = WEBrick::HTTPServer.new(:Port => 80)
	server.mount "/", Algorun
	trap("INT") {
		server.shutdown
	}
	server.start
end
