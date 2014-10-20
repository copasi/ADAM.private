require 'net/http'
require 'json'
input = File.read('react.json')
# json = JSON.parse(input)
uri = URI('http://0.0.0.0:1234/run')
res = Net::HTTP.post_form(uri, 'input' => input)
puts res.body
