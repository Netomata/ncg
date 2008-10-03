require 'netomata'
require 'ruby-debug'

fa = Netomata::Node.new
fa.import_file(open("sample.neto"), "!xyzzy")
debugger
pp fa
