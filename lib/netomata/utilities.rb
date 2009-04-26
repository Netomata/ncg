# $Id$
# Copyright (C) 2008, 2009 Netomata, Inc.  All Rights Reserved. 
# Please review accompanying 'LICENSE' file or
# http://www.netomata.com/docs/licenses/ncg for important notices,
# disclaimers, and license terms.

module Netomata::Utilities
    def self.included(receiver)
	receiver.extend(ClassMethods)
    end
end

module Netomata::Utilities::ClassMethods
    # :call-seq:
    # 	super_method(symbol) -> Method
    #
    # Get a Method handle on the named instance method from self's superclass,
    # rather than from self's own class.  This is a way to explicitly
    # access a superclass method even when a method by the same name has
    # been defined in the current class.
    def super_method(sym)
	self.class.superclass.instance_method(sym).bind(self)
    end

    # :call-seq:
    # 	super_send(symbol, *args) -> obj
    #
    # Invoke superclass instance method named _symbol_ with _args_. 
    # This is a way to explicitly invoke a superclass method even when
    # a method by the same name has been defined in the current class.
    def super_send(sym,*args)
	super_method(sym).call(*args)
    end
    
    # :call-seq:
    # 	buildkey(*parts) -> String
    #
    # Make a key from an array of strings, using "!" as a separator.
    def buildkey(*a)
	return nil if (a.nil?)
	return nil if (a.size == 0)
	return "(.)" if (a.size == 1 && a.first.nil?)
	r = String.new
	ad = a.dup
	until (ad.size == 1) do
	    if ad.first.nil? then
		ad.shift
		next
	    end
	    r << ad.shift
	    r << "!" if ( r[-1..-1] != "!")
	end
	r << ad.shift
	r
    end

    # :call-seq:
    # 	filename_to_key(filename) -> key
    #
    # Convert a filename to a key, by 
    # 1. converting ".." elements to "(..)"
    # 2. converting "." elements "(.)"
    # 3. replacing "/" with "!"
    def filename_to_key(f)
	# special case for "/" => "!"
	if (f.eql?(File::Separator)) then
	    return "!"
	end
	parts = Array.new
	f.split(File::Separator).each { |e| 
	    case e
	    when ".." then
		parts << "(..)"
	    when "." then
		parts << "(.)"
	    else
		parts << e
	    end
	}
	parts.join("!")
    end

    # :call-seq:
    # 	ip_union(ip_a, ip_b) -> ip
    #
    # Arguments _ip_a_ and _ip_b_, and result _ip_, are all IP
    # addresses represented as strings
    #
    # Returns the bitwise OR of two IP addresses, to merge them.  For example:
    # 	ip_union("10.5.0.0", "0.0.16.34") => "10.5.16.34"
    # 	ip_union("10.5.1.0", "0.0.16.34") => "10.5.17.34"
    def ip_union(s1, s2, *rest)
	if (rest.size > 0) then
	    return ip_union(ip_union(s1, s2), rest[0], *rest[1..-1])
	else
	    ip1 = IPAddr.new(s1)
	    ip2 = IPAddr.new(s2)
	    ipr = ip1 | ip2
	    return ipr.to_s
	end
    end

    # :call-seq:
    # 	relative_filename(basename, filename) -> string
    #
    # Expands filename "filename" relative to another filename "basename",
    # returning the expanded filename.  For example:
    #	relative_filename("/a/b/c", "d") -> "/a/b/d"
    #	relative_filename("/a/b/c", "d/e") -> "/a/b/d/e"
    # Special case: if "filename" starts with "/", it is treated as absolute,
    # and returned as-is, not relative to basename.
    #	relative_filename("/a/b/c", "/d/e") -> "/d/e"
    def relative_filename(basename, filename)
	if (filename[0..0] == "/") then
	    # filename begins with "/", so treat as absolute and
	    # simply return filename
	    return filename
	end
	basedir = File.dirname(basename)
	return File.join(basedir,filename)
    end

    # For use in template headers, to check whether needed arguments have
    # been passed as instance variables.  Raises an ArgumentError if _name_
    # (passed as a string) doesn't exist as an instance variable, or exists
    # but isn't of class _expected_class_ (Netomata::Node, by default).
    # Otherwise returns true.
    def template_arg(name, expected_class=Netomata::Node)
	if ! instance_variables.member?(name) then
	    raise ArgumentError, "argument '#{name}' expected, but not defined"
	end
	if (! expected_class.nil?) then
	    if (! instance_variable_get(name).is_a?(expected_class)) then
		raise ArgumentError, "argument '#{name}' expected to be of class '#{expected_class}', but is of class '#{instance_variable_get(name).class}'"
	    end
	end
	true
    end

    # For use in template headers, to check whether needed arguments have
    # been passed as instance variables.  Raises an ArgumentError if any
    # of the following tests fail:
    # 1. _name_ (passed as a string) exists as an instance variable
    # 2. _name_ is a Netomata::Node
    # 3. _name_[_key_] exists
    # 4. _name_[_key_] is of class _expected_class_ (String, by default)
    # Otherwise returns true.
    def template_arg_node_key(name, key, expected_class=String)
	template_arg(name, Netomata::Node)
	if (! instance_variable_get(name).has_key?(key)) then
	    raise ArgumentError, "argument '#{name}' expected to have key '#{key}', but does not"
	else
	    if (! expected_class.nil?) then
		if (! instance_variable_get(name).fetch(key).is_a?(expected_class)) then
		    raise ArgumentError, "argument '#{name}' key '#{key}' expected to be of class '#{expected_class}', but is of class '#{instance_variable_get(name).fetch(key).class}'"
		end
	    end
	end
	true
    end
end
