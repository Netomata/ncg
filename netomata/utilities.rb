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
end
