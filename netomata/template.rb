class Netomata::Template

    include Netomata::Utilities::ClassMethods
    include Netomata::Utilities

    @@cache = Hash.new

    attr_reader :template

    def initialize(filename)
	# make a private @erb_result variable, to keep ERB from overwriting
	# global _erbout (which is what it does by default)
	@erb_result = ""
	if (! @@cache.has_key?(filename)) then
	    f = File.new(filename)
	    begin
		# FIXME: should figure out what appropriate save_level is,
		# and how to make it work
		@@cache[filename] = ERB.new(f.read, 0, "<>", "@erb_result")
	    rescue => exc
		raise exc.exception("template '#{filename}'\n" + exc.message)
	    end
	    f.close
	end
	@template = @@cache[filename]
    end

    def result(b = nil)
	@template.result(b)
    end

end

class Netomata::Template::Context

    include Netomata::Utilities::ClassMethods
    include Netomata::Utilities

    def initialize(h = nil)
	if (! h.nil?) then
	    if (! h.is_a?(Hash)) then
		raise ArgumentError, "optional argument must be hash"
	    end
	    set_h(h)
	end
    end

    def set(k,v)
	instance_variable_set(k,v)
    end

    def set_h(h)
	h.each { |k,v|
	    instance_variable_set(k,v)
	}
    end

    def binding
 	super
    end

    def eval(s)
	super(s,binding)
    end

    def apply_idiom(idiom, node, vars=nil)
	raise ArgumentError, "Not a node" if (! node.is_a?(Netomata::Node))
	inode = node[buildkey("(...)","idioms",idiom)]
	raise "Idiom \"#{idiom}\" not found for node #{node.key}" if inode.nil?
	Netomata::Template::Context.apply_by_node(inode, vars)
    end

    # class methods

    def self.apply_by_filename(name, vars=nil)
	Netomata::Template::Result.new(name, vars).result.chomp
    end

    def self.apply_by_node(node, vars=nil)
	filename = node["ncg_template"]
	Netomata::Template::Context.apply_by_filename(filename, vars)
    end


end

class Netomata::Template::Result

    include Netomata::Utilities::ClassMethods
    include Netomata::Utilities

    attr_reader :result

    def initialize(filename, vars=nil)
	@template = Netomata::Template.new(filename)
	@context = Netomata::Template::Context.new(vars)
	@result = @template.result(@context.binding)
    end
end
