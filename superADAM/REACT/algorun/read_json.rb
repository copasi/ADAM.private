require 'open-uri'
require 'json'
require 'pp'

# read input json file
input = File.read('react.json')

# create json structure
json = JSON.parse(input)
output=""
err=[]
files_to_download=[]

# fetching P value
unless (p=json['P']).nil?
	output+="P=%s\n" % p
else
	err.push("Error: missing P value")
end

# fetching N value
unless (n=json['N']).nil?
	output+="N=%s\n" % n
else
	err.push("Error: missing N value")
end

# fetching WT value
output+="WT = {"
if !(wt=json['wildType']).nil?
	files_to_download=files_to_download|wt
	output+="\"#{wt.join("\",\"")}\""
end
output+="}\n"

# fetching KO value
output+="KO = {"
if !(ko=json['knockOut']).nil?
	tmp=[]
	ko.each do |z|
		z.each do |k,v|
			files_to_download.push(k)
			tmp.push("(%s, \"%s\")" % [v,k.split('/').last])
		end
	end
	output+=tmp.join(",")
end
output+="}\n"

# download remote files and copy them in the current directory
unless not err.empty? and true
	files_to_download.each do |uri|
		file_name = uri.split('/').last
		begin
			file_contents = open(uri) { |f| f.read }
		rescue StandardError=>e
			err.push("Error: #{e}")
		else
			File.open(file_name,'w') { |file| file.write(file_contents) }
		end
	end
end

# return final output unless an error was detected
unless not err.empty?
	puts output
	pp files_to_download
else
	puts err.join("\n")
end
