# add pretty_print methods to the Dictionary class
class Dictionary

        def pretty_print(q)
	    q.pp_hash self
	end

	def pretty_print_cycle(q)
	    q.text(empty? ? '{}' : '{...}')
        end
end

class Netomata::Node < Dictionary

    def initialize
	super()
    end

    # return true if keys/values of this node match
    # an expression of the form:
    # 	(key=value[,key2=value2 ...])
    def node_match?(m)
	if m.match(/^\(\+\)$/) then
	    # match target is "(+)", which is magic for a new node
	    return false
	end
	# strip parentheses and split into parts
	m.gsub(/[()]/,"").split(/,/).each { |mp|
	    k,v = mp.split(/=/)
	    if (k.nil? or v.nil?) then
		raise ArgumentError, "invalid syntax for node_match term"
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

    # return array of subnodes that match expression
    def subnode_matches(m)
	ra = Array.new
	self.each { |k,v|
	    if v.node_match?(m) then
		ra << v
	    end
	}
	return ra
    end

    # return single match of subnodes that match expression, or
    # raise an error if more than 1
    def subnode_match_one(m)
	ra = self.subnode_matches(m)
	case ra.length
	    when 0 then return nil
	    when 1 then return ra[0]
	    else raise RuntimeError, "matched more than 1 subnode"
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
		# l contains a "(...)" selector; dereference
		return self.subnode_match_one(l)
	    else
		return super(l)
	    end
	else
	    if (l.match(/^\(.*\)$/)) then
		# l contains a "(...)" selector; dereference
		# if dereferencing l returns nil, then we're done
		result = self.subnode_match_one(l)
		if result.nil? then
		    return nil
		else
		    return self.subnode_match_one(l)[r]
		end
	    else
		return super(l)[r]
	    end
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
		if (l.match(/^\(\+\)$/)) then
		    # l is an "increment and create new" statement
		    mk = self.keys.max
		    if (mk.nil?) then
			nk = "1"
		    else
			nk = mk.succ
		    end
		    self[nk] = Netomata::Node.new
		    self[nk][r] = v
		    return v
		end
		if (l.match(/^\(.*\)$/)) then
		    # l is a match statement, but isn't matching anything
		    raise ArgumentError,
			"no nodes found with key \"#{l}\""
		end
		self[l] = Netomata::Node.new
	    end
	    if (self[l].class != Netomata::Node) then
		raise ArgumentError, "key \"#{l}\" already defined, but value is not of type Netomata::Node"
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

# fa = Netomata::Node.new
# fa.import(open("vlans"), "!vlans")
# pp(fa)
# pp(fa["!vlans"])
# pp(fa["!vlans!(c_name=IPMI)"])
# pp(fa["!vlans!(c_name=IPMI)!c_id"])
# pp(fa["!vlans!(c_id=48)!c_name"])
# pp(fa["!vlans!(c_activ=maybe)!c_name"])
# pp(fa["!vlans!(c_activ=yes)!c_name"])
