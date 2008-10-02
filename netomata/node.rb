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

    # Convert a "()" key selector to the appropriate key
    # 	(+): returns new key, successor to current max key
    # 	(>): returns current max key
    # 	(<): returns current min key
    # 	(subkey=value,[subkey2=value ...]): returns key of first subnode
    # 		whose subkey(s) match list of subkey/value criteria
    def selector_to_key(s)

	m = s.match(/^\((.*)\)$/)
	if m.nil? then
	    # s isn't a "( ... )" key selector, so just return s
	    return s
	else
	    case m[1]
	    when ">"
		return self.keys.max
	    when "<"
		return self.keys.min
	    when "+"
	    	r = self.keys.max
		if (r.nil?) then
		    return "1"
		else
		    return r.succ
		end
	    when /.*=.*/
		r = selector_criteria_to_keys(s)
		if (r.class == Array) then
		    raise ArgumentError,
		    	"selector \"#{s}\" matches multiple subnodes"
		end
		return r
	    else
		raise ArgumentError, "Unknown selector \"#{s}\""
	    end
	end
    end

    # Convert a "(subkey=value,[subkey2=value2 ...])" key selector criteria
    # to the array of the keys of the subnodes whose subkey(s) match the list
    # of subkey/value criteria
    def selector_criteria_to_keys(s)
	# construct an array of [key, value] pairs to check subnodes against
	ca = Array.new
	s.gsub(/[()]/,"").split(/,/).each { |mp|
	    k,v = mp.split(/=/)
	    if (k.nil? or v.nil?) then
		raise ArgumentError, "invalid syntax for node_match term"
	    end
	    ca << [k,v]
	}
	# start with an empty array of results
	ra = Array.new
	self.keys.each { |k|
	    if self[k].node_match_array?(ca) then
		ra << k
	    end
	}
	case ra.length
	    when 0 then return nil
	    when 1 then return ra[0]
	    else return ra
	end
    end

    # check to see whether current node matches an array of [key,value] pairs
    def node_match_array?(ca)
	ca.each { |k,v|
	    if ( ! self.has_key?(k)) then
		return false
	    end
	    if (self[k] != v) then
		return false
	    end
	}
	return true
    end

    def [](k)
	puts "[](\"#{k}\")" if $debug
	# strip/skip leading "!", and split into left and right keys
	# TODO: figure out what to _really_ do about keys beginning with "!"
	l,r = k.gsub(/^!+/,"").split("!",2)
	if r.nil? then
	    # if r is nil, then there was no "!" in the key
	    return super(selector_to_key(l))
	else
	    return super(selector_to_key(l))[r]
	end
    end

    def []=(k,v)
	puts "[]=(\"#{k}\", \"#{v}\")" if $debug
	# strip/skip leading "!", and split into left and right keys
	# TODO: figure out what to _really_ do about keys beginning with "!"
	l,r = k.gsub(/^!+/,"").split("!",2)
	if r.nil? then
	    # if r is nil, then there was no "!" in the key
	    # TODO: refactor this and similar code below
	    if (l.match(/^\(\+\)$/)) then
		# l is an "increment and create new" statement
		mk = self.keys.max
		if (mk.nil?) then
		    nk = "1"
		else
		    nk = mk.succ
		end
		self[nk] = v
		return v
	    else
		super(l,v)
	    end
	else
	    puts "self[\"#{l}\"] => #{self[l]}" if $debug
	    if self[l].nil? then
		# if intermediate node doesn't exist, create it
		puts "self[\"#{l}\"] doesn't exist" if $debug
		# TODO: refactor this and similar code above
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
