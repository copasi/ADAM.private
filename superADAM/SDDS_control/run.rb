#!/usr/bin/ruby
require './algorun/Model.rb'
input = File.read(ARGV[0])
json = JSON.parse(input)
model=Model.new(json,'./SDDS')
model.run()
model.render_output()
model.clean_temp_files()
