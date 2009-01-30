# $Id$
# Copyright (c) 2008 Netomata, Inc.  All Rights Reserved. 
# Please review accompanying 'LICENSE' file or
# http://www.netomata.com/license_v1 for important notices,
# disclaimers, and license terms (GPL v2.0 or alternative).

class Netomata::Template
end

class Netomata::Template::FromString

    include Netomata::Utilities::ClassMethods
    include Netomata::Utilities

    attr_reader :erb
    attr_reader :source

    def initialize(str,source="UNKNOWN")
	@source = source.dup
	# make a private @erb_result variable, to keep ERB from overwriting
	# global _erbout (which is what it does by default)
	@erb_result = String.new
	# FIXME: should figure out what appropriate save_level is,
	# and how to make it work
	@erb = ERB.new(str, 0, "<>", "@erb_result")
    end

    # This method shouldn't be called anywhere, because it doesn't pass
    # in any context to the code being evaluated by ERB.  Instead, all
    # calls should be via result_from_vars.
    def result(binding = nil)
	raise "Unexpected call to #{self.class}#result"
    end

    def result_from_vars(vars = nil)
	context = Netomata::Template::Context.new(vars)
	begin
	    @erb.result(context.binding)
	rescue => exc
	    handle_exception(exc,vars)
	    raise exc.exception
	end
    end

    #########################
    #### Private methods ####
    #########################

    private

    def handle_exception(exc = nil, vars = nil)
	if exc.nil? then
	    raise "Exception not passed to #{self.class}#handle_exception"
	end

	# fix the backtrace, so it lists the filename that the exception
	# occurred in, rather than just "(erb)"
	if @source.match(/^(.*):(\d+)$/) then
	    file = $1
	    line = $2.to_i
	else
	    file = @source
	    line = nil
	end
	bt = exc.backtrace
	bt.each { |e|
	    if e.match(/^\(erb\):(\d+)(:.*)?/) then
		if (line.nil?) then
		    # source doesn't include a line number, so just use the
		    # one from the original backtrace element
		    e.replace(file + ":" + $1)
		else
		    # source includes a line number, so add it to the one
		    # from the backtrace element (and subtract 1, since
		    # lines are counted from 1 not 0)
		    e.replace(file + ":" + ($1.to_i + line - 1).to_s)
		end
	    end
	}
	exc.set_backtrace(bt)

	# if $error_dump is set, dump error and vars to that file
	if ! $error_dump.nil? then
	    ef = open($error_dump, "w")
	    ef.print "ERROR(#{exc.class}): #{exc.message}\n"
	    ef.print "---------\n"
	    ef.print "BACKTRACE\n"
	    ef.print "---------\n"
	    ef.print bt.join("\n")
	    ef.print "\n"
	    ef.print "-------\n"
	    ef.print "CONTEXT\n"
	    ef.print "-------\n"
	    vars.each { |k,v|
		if v.is_a?(Netomata::Node) then
		    ef.print "#{k} = {\n"
		    v.dump(ef,1,true)
		    ef.print "}\n"
		else
		    ef.print "#{k} = "
		    PP::pp(v, ef)
		end
	    }
	    ef.close
	end

	return exc
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
	return super(@@cache[filename], filename)
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
	Netomata::Template::FromFile.new(filename).result_from_vars(vars).chomp
    end

    def self.apply_by_node(node, vars=nil)
	filename = node["ncg_template"]
	Netomata::Template::Context.apply_by_filename(filename, vars)
    end
end
