require './algorun/Model.rb'
input = File.read(ARGV[0])
json = JSON.parse(input)
model=Model.new(json,'./SDDS')
model.run()
puts model.render_output()
model.clean_temp_files()
