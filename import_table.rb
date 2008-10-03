require 'netomata'
require 'ruby-debug'

fa = Netomata::Node.new
fa["!xyzzy!devices!(+)!hostname"] = "switch-1"
fa["!xyzzy!devices!(+)!hostname"] = "switch-2"
fa.import_file(open("sample.templates.neto"), "!xyzzy")
$debug = false
fa.import_table(open("interfaces"), "!xyzzy")
debugger
#pp fa["!xyzzy!devices!(hostname=switch-1)!interfaces!(name=Gig1/10)"]
#pp fa["!xyzzy!devices!(hostname=switch-1)!interfaces!(name=Gig1/10)!target"]
#pp fa["!xyzzy!devices!(hostname=switch-1)!interfaces!(type=host)"]
# debugger
pp fa
