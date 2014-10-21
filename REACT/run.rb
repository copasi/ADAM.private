#!/usr/bin/ruby
require './algorun/Task.rb'
input = File.read(ARGV[0])
json = JSON.parse(input)
task=Task.new(json,'./React')
task.run()
puts task.render_output()
task.clean_temp_files()
