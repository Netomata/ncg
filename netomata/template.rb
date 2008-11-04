class Netomata::Template
end

class Netomata::Template::FromString

    include Netomata::Utilities::ClassMethods
    include Netomata::Utilities

    attr_reader :erb

    def initialize(str)
	# make a private @erb_result variable, to keep ERB from overwriting
	# global _erbout (which is what it does by default)
	@erb_result = String.new
	# FIXME: should figure out what appropriate save_level is,
	# and how to make it work
	@erb = ERB.new(str, 0, "<>", "@erb_result")
    end

    def result(binding = nil)
	@erb.result(binding)
    end

    def result_from_vars(vars = nil)
	context = Netomata::Template::Context.new(vars)
	@erb.result(context.binding)
    end
end

class Netomata::Template::FromFile < Netomata::Template::FromString

    include Netomata::Utilities::ClassMethods
    include Netomata::Utilities

    @@cache = Hash.new

    def initialize(filename)
	if (! @@cache.has_key?(filename)) then
	    begin
	    	f = File.new(filename)
		@@cache[filename] = f.read
		f.close
	    rescue => exc
		raise exc.exception("template '#{filename}'\n" + exc.message)
	    end
	end
	return super(@@cache[filename])
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

    def self.apply_by_filename(filename, vars=nil)
	Netomata::Template::Result.new(filename, vars).result.chomp
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
	@erb = Netomata::Template::FromFile.new(filename)
	@context = Netomata::Template::Context.new(vars)
	@result = @erb.result(@context.binding)
    end
end
