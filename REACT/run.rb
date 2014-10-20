#!/usr/bin/ruby
require './algorun/Task.rb'
input = File.read(ARGV[0])
json = JSON.parse(input)
model=Task.new(json,'./React')
model.run()
puts model.render_output()
#model.clean_temp_files()
