module Netomata::Utilities
    def super_method(sym)
	self.class.superclass.instance_method(sym).bind(self)
    end

    def super_send(sym,*args)
	super_method(sym).call(*args)
    end
end
