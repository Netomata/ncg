require 'netomata'
require 'erb'
require 'ruby-debug'

net = Netomata::Node.new
net.import_file(open("sample.neto"))
puts net.keys_r.join("\n")
