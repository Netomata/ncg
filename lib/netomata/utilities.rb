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
    # compare_parts(a,b) -> -1, 0, or 1
    #
    # Compares two interface- or version-style names, and determine what
    # order they should sort in.  This is similar to the Ruby core
    # String#<=> operator, but it works in a way that is more useful
    # for comparing things like interface names, version numbers, and such.
    #
    # Returns:
    #
    # * -1 if _a_ should sort before _b_
    # * 0 if _a_ and _b_ are equivalent
    # * 1 if _b_ should sort before _a_
    #
    # To compare the arguments _a_ and _b_, they are first broken into parts.
    # Each part, in turn, is the longest-possible string of either:
    # * letters [a-zA-Z]
    # * digits [0-9]
    # * anything else (i.e., a string of 1 or more non-alphanumeric characters)
    #
    # Then, the corresponding parts of each argument are compared in turn,
    # until an answer is determined, subject to the following rules: 
    # * If both parts are integers, they are compared numerically (so
    #   that "2" is less than "10", even though alphabetically "10" sorts
    #   before "2").
    # * Otherwise, both parts are compared as text strings (case sensitive).
    # If the corresponding parts of both arguments are equal by these rules,
    # then the next pair of corresponding parts is considered, and so forth,
    # until an answer is determined.
    # 
    # For example, consider a list of interfaces; sorted normally (not using
    # compare_parts), their order would be:
    #
    # * FastEthernet1
    # * FastEthernet10
    # * FastEthernet10.10
    # * FastEthernet10.2
    # * FastEthernet2
    #
    # compare_parts would break each of these down into the following parts
    # (shown by spaces) for comparison:
    #
    # * FastEthernet1		-> FastEthernet 1
    # * FastEthernet10		-> FastEthernet 10
    # * FastEthernet10.10	-> FastEthernet 10 . 10
    # * FastEthernet10.2	-> FastEthernet 10 . 2
    # * FastEthernet2		-> FastEthernet 2
    #
    # So, sorted using compare_parts for comparison, they would be:
    #
    # * FastEthernet1
    # * FastEthernet2
    # * FastEthernet10
    # * FastEthernet10.2
    # * FastEthernet10.10

    def compare_parts(a,b)
	case [a.nil?, b.nil?]
	when [true,true]
	    return 0
	when [true,false]
	    return 1
	when [false,true]
	    return -1
	end
	
	# separate args into arrays where each element is either
	# 	- an alphabetic string
	# 	- a numeric string
	# 	- a separator string (string of 1 or more non-alphanumerics)
	ap = a.scan(/[a-zA-Z]+|[0-9]+|[^0-9a-zA-Z]+/)
	bp = b.scan(/[a-zA-Z]+|[0-9]+|[^0-9a-zA-Z]+/)
	
	until false do
	    return 0 if (ap.empty? && bp.empty?)
	    return -1 if ap.empty?
	    return 1 if bp.empty?

	    ae = ap.shift
	    be = bp.shift

	    # if both are numbers, compare numerically (so "2" is before "10")
	    if (ae.match(/^[0-9]*$/) && be.match(/^[0-9]*$/)) then
		r = (ae.to_i <=> be.to_i)
		return r if (r != 0)
	    else
		# else compare as strings
		r = (ae <=> be)
		return r if (r != 0)
	    end
	end

	# should never get here
	raise "compare_parts logic error"
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
	s = name.to_sym
	if ! instance_variables.member?(s) then
	    raise ArgumentError, "argument '#{name}' expected, but not defined"
	end
	if (! expected_class.nil?) then
	    if (! instance_variable_get(s).is_a?(expected_class)) then
		raise ArgumentError, "argument '#{name}' expected to be of class '#{expected_class}', but is of class '#{instance_variable_get(s).class}'"
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
