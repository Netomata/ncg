require 'rubygems'
require 'facets'
require 'facets/dictionary'
require 'pp'
require 'breakpoint'

# add pretty_print methods to the Dictionary class
class Dictionary

        def pretty_print(q)
	    q.pp_hash self
	end

	def pretty_print_cycle(q)
	    q.text(empty? ? '{}' : '{...}')
        end
end

class Netomata

    class Element < Dictionary

	def initialize
	    super()
	end

	# return true if keys/values of this element match
	# an expression of the form:
	# 	(key=value[,key2=value2 ...])
	def elementmatch?(m)
	    # strip parentheses and split into parts
	    m.gsub(/[()]/,"").split(/,/).each { |mp|
		k,v = mp.split(/=/)
		if (k.nil? or v.nil?) then
		    raise ArgumentError, "invalid syntax for elementmatch term"
		end
		if (! self.has_key?(k)) then
		    return false;
		else
		    if (self[k].to_s != v.to_s) then
			return false;
		    end
		end
	    }
	    return true;
	end

	# return array of subelements that match expression
	def subelementmatches(m)
	    ra = Array.new
	    self.each { |k,v|
		if v.elementmatch?(m) then
		    ra << v
		end
	    }
	    return ra
	end

	# return single match of subelements that match expression, or
	# raise an error if more than 1
	def subelementmatch1(m)
	    ra = self.subelementmatches(m)
	    case ra.length
		when 0 then return nil
		when 1 then return ra[0]
		else raise RuntimeError, "matched more than 1 subelement"
	    end
	end

	def [](k)
	    puts "[](\"#{k}\")" if $debug
	    # strip/skip leading "!", and split into left and right keys
	    # TODO: figure out what to _really_ do about keys beginning with "!"
	    l,r = k.gsub(/^!+/,"").split("!",2)
	    if r.nil? then
		# if r is nil, then there was no "!" in the key
		if (l.match(/^\(.*\)$/)) then
		    # l contains a "(...)" selector
		end
		super(l)
	    else
		super(l)[r]
	    end
	end

	def []=(k,v)
	    puts "[]=(\"#{k}\", \"#{v}\")" if $debug
	    # strip/skip leading "!", and split into left and right keys
	    # TODO: figure out what to _really_ do about keys beginning with "!"
	    l,r = k.gsub(/^!+/,"").split("!",2)
	    if r.nil? then
		# if r is nil, then there was no "!" in the key
		super(l,v)
	    else
		puts "self[\"#{l}\"] => #{self[l]}" if $debug
		if self[l].nil? then
		    # if intermediate node doesn't exist, create it
		    puts "self[\"#{l}\"] doesn't exist" if $debug
		    self[l] = Netomata::Element.new
		end
		if (self[l].class != Netomata::Element) then
		    raise ArgumentError, "key \"#{l}\" already defined, but value is not of type Netomata::Element"
		end
		self[l][r]=v
	    end
	end

	def import(io,basekey) 
	    io.each_line { |l|
		l.chomp!			# eliminate trailing newline
		l.gsub!(/\s*#.*/, "")	# eliminate trailing comments
		case l
		when /^$/ then
		    next	# skip blank lines
		when /^#/ then
		    next	# skip comments
		when /^@/ then
		    next	# skip variable specs (for now) FIXME
		when /^%/ then
		    # strip leading marker and whitespace
		    l.gsub!(/^%\s*/,"")
		    @fields = l.split(/\t+/)
		else
		    if (@fields.nil?) then
			raise "Fields must be defined before first data line"
		    end
		    d = l.split(/\t+/)
		    if (d.length != @fields.length) then
			raise "Wrong number of fields in line; expected #{@fields.length}, got #{d.length}"
		    end
		    @fields.each { |f|
			v = d.shift
			# if the string value is really an integer
			# (determined by converting it to an integer
			# and then back to a string, and comparing that
			# to the original string), then push the value
			# as an integer; otherwise, push it as a string
			if (v.to_i.to_s == v) then
			    v = v.to_i
			end
			self[basekey + "!" + io.lineno.to_s + "!" + f] = v
		    }
		end
	    }
	end
    end
end

#fa = Netomata::Element.new
#fa.import(open("vlans.new"), "!vlans")
#pp(fa)
