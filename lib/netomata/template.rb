# $Id$
# Copyright (C) 2008-2010 Netomata, Inc.  All Rights Reserved. 
# Please review accompanying 'LICENSE' file or
# http://www.netomata.com/docs/licenses/ncg for important notices,
# disclaimers, and license terms.

class Netomata::Template

    include Netomata::Utilities::ClassMethods
    include Netomata::Utilities

    attr_reader :erb, :erb_result, :filename, :lineno, :text

    # :call-seq:
    #   new ( filename [ , lineno = nil [ , contents = nil ] ] )
    #
    # Create a new template from the contents of the file named by _filename_.
    # Optional argument _lineno_ specifies the line number within the file,
    # and defaults to 1.
    # Optional argument _contents_ specifies the contents to be used, instead
    # of reading from the named file.
    def initialize(filename, lineno=nil, contents=nil)
	# If we aren't passed a lineno and contents, read the named file
	if (contents.nil?) then
	    open(filename) { |io|
		contents = io.read
	    }
	    lineno = 1
	end
	@filename = filename.dup
	@lineno = lineno
	@text = contents.dup
	@erb_result = ""
	@erb = ERB.new(@text, 0, "-", "@erb_result")
	@erb.filename = filename.dup
    end

    # :call-seq:
    #   result_from_vars(vars = nil) -> output_string
    #
    # _vars_ should be a hash of ["@var" => object] tuples, which
    # are passed as instance variable names and values to the template,
    # which is then evaluated via ERB, with the ERB results
    # returned in _output_string_
    def result_from_vars(vars = nil)
        context = Netomata::Template::Context.new(vars)
        begin
            r = @erb.result(context.binding)
        rescue => exc
            handle_exception(exc,vars)
            raise exc.exception
        end
        r
    end

    #################
    # Class Methods #
    #################

    # Evaluates a template from the contents of _filename_
    # in a context with instance variables specified by _vars_
    # (a hash of ["@var" => value] tuples), and returns the result.
    def self.apply_by_filename(filename, vars=nil)
	Netomata::Template.new(filename).result_from_vars(vars).chomp
    end

    # Evaluates a template from the file named by _node_["ncg_template"]
    # in a context with instance variables specified by _vars_
    # (a hash of ["@var" => value] tuples), and returns the result.
    def self.apply_by_node(node, vars=nil)
	raise ArgumentError, "Not a node" if (! node.is_a?(Netomata::Node))
	unless (filename = node["ncg_template"])
	    raise "Node '#{node.key}' has no 'ncg_template' key"
	end
	Netomata::Template.apply_by_filename(filename, vars)
    end

    # Looks for a named _idiom_ node in _node_["(...)!idioms"], evaluates
    # it with instance variables specified by _vars_
    # (a hash of ["@var" => value] tuples), and returns the result.
    def self.apply_idiom(idiom, node, vars=nil)
	raise ArgumentError, "Not a node" if (! node.is_a?(Netomata::Node))
	inode = node[buildkey("(...)","idioms",idiom)]
	raise "Idiom \"#{idiom}\" not found for node #{node.key}" if inode.nil?
	Netomata::Template.apply_by_node(inode, vars)
    end

    #########################
    #### Private methods ####
    #########################

    private

    # :call-seq:
    #	handle_exception(exc = nil, vars = nil) -> exc
    #
    # This method fixes the backtrace of the passed Exception _exc_ to
    # more accurately indicate the source of the exception.
    #
    # Also, if global $error_dump is set, a file by that name is created,
    # and a copy of the error, backtrace, and dump of _vars_ is written to
    # that file, to provide context for someone debugging the error.
    def handle_exception(exc = nil, vars = nil)
	if exc.nil? then
	    raise "Exception not passed to #{self.class}#handle_exception"
	end

	bt = exc.backtrace
	# fix the backtrace, so it lists the filename that the exception
	# occurred in, rather than just "(erb)"
	bt.each { |e|
	    if e.match(/^\(erb\):(\d+)(:.*)?/) then
		# add our line number, to the one from the backtrace element
		# (and subtract 1, since lines are counted from 1 not 0)
		e.replace(@filename + ":" + ($1.to_i + @lineno - 1).to_s)
	    end
	}
	exc.set_backtrace(bt)

	# if $error_dump is set, dump error and vars to that file
	if ! $error_dump.nil? then
	    c = 0
	    while File.file?("#{$error_dump}.#{c}") do
		c += 1
	    end
	    ef = open("#{$error_dump}.#{c}", "w")
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

	exc
    end
end

class Netomata
    class Template
	class Context
	    module Helpers
	    end
	end
    end
end

class Netomata::Template::Context

    include Netomata::Utilities::ClassMethods
    include Netomata::Utilities

    # Helper methods intended for use within templates

    module Helpers

	# Proxy for Netomata::Template.apply_by_filename()
	def apply_by_filename(*args)
	    Netomata::Template.apply_by_filename(*args)
	end

	# Proxy for Netomata::Template.apply_by_node()
	def apply_by_node(*args)
	    Netomata::Template.apply_by_node(*args)
	end

	# Proxy for Netomata::Template.apply_idiom()
	def apply_idiom(*args)
	    Netomata::Template.apply_idiom(*args)
	end

	# Return a string that is a multi-line header suitable for placing
	# as a comment at the beginning of a generated config file, describing
	# what tool was used to generate the config, what target key it was
	# generated for, what date it was generated on, what user, hostname, and
	# directory name it was generated for, and what arguments the generating
	# program was invoked with.
	#
	# _prefix_, if defined, is prepended to every line of the generated header.
	# It should be whatever marks the rest of the line as a comment in the
	# generated config file.
	#
	# _before_, if defined, is used as the very first line of the generated
	# header.  It should be whatever marks the beginning of a multi-line
	# comment in the generated config file.  _prefix_ is *not* applied to
	# _before_, so _before_ should include _prefix_ if necessary.
	#
	# _after_, if defined, is used as the very last line of the generated
	# header.  It should be whatever marks the end of a multi-line
	# comment in the generated config file.  _prefix_ is *not* applied to
	# _after_, so _after_ should include _prefix_ if necessary.
	#
	# For example, to generate headers suitable for a shell script,
	# you would do
	# 	emit_header("# ", nil, nil)
	# which would return a header of the form
	# 	# line 1
	# 	# line 2
	# 	# ...
	#
	# To generate headers for a C-style config, you would do
	# 	emit_header(" *  ", "/*", " */")
	# which would return a header of the form
	# 	/*
	# 	 * line 1
	# 	 * line 2
	# 	 * ...
	# 	 */
	def emit_header(prefix=nil, before=nil, after=nil)
	    argv = ARGV.dup
	    argv.each do |e|
		if e.include?(" ") then
		    e.replace('"' + e + '"')
		end
	    end
	    cmd = $0 + " " + argv.join(" ")

	    t = <<EOS
Generated by Netomata Config Generator (ncg)
    http://www.netomata.com/
--------
Target: #{@target["name"]}
Date: #{Time.now.localtime.to_s}
User: #{Etc.getlogin}
Host: #{Socket.gethostname}
Directory: #{Dir.getwd}
Command: #{cmd}
--------
Templates (but not output generated from templates) are
Copyright (C) 2008-2010 Netomata, Inc.  All Rights Reserved. 
Please review accompanying 'LICENSE' file or
http://www.netomata.com/docs/licenses/ncg for important notices,
disclaimers, and license terms.
EOS

	    if (! prefix.nil?) then
		t.gsub!(/^/, prefix)
	    end

	    if (! before.nil?) then
		t.insert(0, before + "\n")
	    end

	    if (! after.nil?) then
		t.insert(-1, after + "\n")
	    end

	    t
	end

	# Include the file named by _filename_, if it exists and is readable
	def include_if_exists(filename, vars=nil)
	    if File.readable?(filename) then
		Netomata::Template.apply_by_filename(filename, vars) + "\n"
	    else
		""
	    end
	end

    end	# module Helpers

    include Helpers

    # Initializes a context for evaluating a Netomata::Template.
    #
    # _h_ is a hash whose keys are instance variable names to be
    # defined in the context, and whose values are the corresponding
    # values for those instance variables.
    def initialize(h = nil)
	if (! h.nil?) then
	    if (! h.is_a?(Hash)) then
		raise ArgumentError, "optional argument must be hash"
	    end
	    set_h(h)
	end
    end

    # Sets an instance variable named _k_ to value _v_ in the current context.
    def set(k,v)
	instance_variable_set(k,v)
    end

    # Sets instance variables for the current context.
    #
    # _h_ is a hash whose keys are instance variable names to be
    # defined in the context, and whose values are the corresponding
    # values for those instance variables.
    def set_h(h)
	h.each { |k,v|
	    instance_variable_set(k,v)
	}
    end

    # Return the binding for this context.
    def binding
 	super
    end

    # Evaluate _s_ in the current context's binding.
    def eval(s)
	super(s,binding)
    end
end
