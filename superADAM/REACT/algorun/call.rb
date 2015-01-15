require 'net/http'
require 'json'
input = File.read('../test/test1/REACT_Input_Example1.json')
json = JSON.parse(input)
uri = URI('http://0.0.0.0:1234/run')
res = Net::HTTP.post_form(uri, 'input' => input)
puts res.body
