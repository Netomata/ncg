class Netomata::Template

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

    def initialize(h = nil)
	if (! h.nil?) then
	    if (h.class != Hash) then
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
end

class Netomata::Template::Result

    attr_reader :result

    def initialize(filename, vars=nil, str=nil)
	@template = Netomata::Template.new(filename)
	@context = Netomata::Template::Context.new(vars)
	@result = @template.result(@context.binding)
    end
end
