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

    def result(binding = nil)
	begin
	    @erb.result(binding)
	rescue => exc
	    fix_exception(exc)
	    raise exc.exception
	end
    end

    def result_from_vars(vars = nil)
	context = Netomata::Template::Context.new(vars)
	begin
	    @erb.result(context.binding)
	rescue => exc
	    fix_exception(exc)
	    raise exc.exception
	end
    end

    #########################
    #### Private methods ####
    #########################

    private

    def fix_exception(exc = nil)
	if exc.nil? then
	    return
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
