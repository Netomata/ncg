require 'netomata'
require 'ruby-debug'

net = Netomata::Node.new
net.import_file(open("sample.neto"), "!net")
# $debug = true
debugger
pp net.keys_r
