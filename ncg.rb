require 'netomata'
require 'erb'
require 'ruby-debug'

net = Netomata::Node.new
net.import_file(open("sample.neto"))
# get the list of targets to generate config files for
net.keys_having_key("ncg_output").each { |target_key|
    unless template_f = net[target_key]["ncg_template"] 
	raise "Target '#{target_key}' has 'ncg_output' key, but no 'ncg_template' key"
    end
    begin
	# FIXME: should figure out what appropriate safe_level is, and how
	# to make it work
	template = ERB.new(File.new(template_f).read, 0, "<>")
    rescue => exc
	raise exc.exception("Target '#{target_key}', ncg_template='#{template_f}'\n" + exc.message)
    end

    # set up shortcut "target" variable for use in templates
    target = net[target_key]

    # debugger

    ofile = File.new(target["ncg_output"], "w")
    ofile.write(template.result(binding))
    ofile.close

    # pp template
}
# $debug = true
# pp net.keys_r
