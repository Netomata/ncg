module Netomata::Utilities
    def self.included(receiver)
	receiver.extend(ClassMethods)
    end
end

module Netomata::Utilities::ClassMethods
    def super_method(sym)
	self.class.superclass.instance_method(sym).bind(self)
    end

    def super_send(sym,*args)
	super_method(sym).call(*args)
    end
    
    # Make a key from a set of components, using "!" as a separator
    def buildkey(*a)
	return nil if (a.nil?)
	return nil if (a.size == 0)
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

    # return the bitwise OR of two IP addresses, to merge them
    # 	ip_union("10.5.0.0", "0.0.16.34") => "10.5.16.34"
    # 	ip_union("10.5.1.0", "0.0.16.34") => "10.5.17.34"
    def ip_union(s1, s2)
	ip1 = IPAddr.new(s1)
	ip2 = IPAddr.new(s2)
	ipr = ip1 | ip2
	return ipr.to_s
    end
end
