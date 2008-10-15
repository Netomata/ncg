require 'netomata'
require 'erb'
require 'ruby-debug'

net = Netomata::Node.new
net.import_file(open("sample.neto"))
# get the list of targets to generate config files for
net.keys_having_key("ncg_output").each { |target_key|
    unless template_filename = net[target_key]["ncg_template"] 
	raise "Target '#{target_key}' has 'ncg_output' key, but no 'ncg_template' key"
    end

    # set up shortcut "target" variable
    target = net[target_key]

    r = Netomata::Template::Result.new(template_filename, {
	"@net" => net,
        "@target_key" => target_key,
        "@target" => target
    })

    of = File.new(target["ncg_output"], "w")
    of.write(r.result)
    of.close
}
# $debug = true
# pp net.keys_r
