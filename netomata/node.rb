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
	    return super(selector_to_key(l),v)
	else
	    nk = selector_to_key(l)
	    if nk.nil? then
		# selector_to_key didn't return anything, so must have
		# been a criteria selector which didn't match anything;
		# nothing we can do about it but raise an error
		raise ArgumentError, "criteria #{l} doesn't match any subnodes"
	    end
	    if self[nk].nil? then
		# path references a node that doesn't exist yet, so create it
		self[nk] = Netomata::Node.new
	    end
	    if self[nk].class != Netomata::Node then
		raise ArgumentError, "key \"#{l}\" already defined, but value is not of type Netomata::Node"
	    end
	    return self[nk][r] = v
	end
    end

    def keys_r(prefix="")
	ra = []
	self.each { |k,v|
	    ra << k.dup.insert(0,prefix + "!")
	    if v.respond_to?(:keys_r) then
		ra.concat(v.keys_r(prefix + "!" + k))
	    end
	}
	ra
    end

    def each_r(prefix="", &block)
	self.each { |k,v|
	    yield(prefix,k,v)
	    if v.respond_to?(:each_r) then
		v.each_r(prefix + "!" + k, &block)
	    end
	}
	self
    end

    def select_r(prefix="", &block)
	ra = []
	each { |k,v| 
	    ra << [(prefix + "!" + k), v] if yield prefix,k,v
	    if v.respond_to?(:select_r) then
		ra.concat(v.select_r(prefix + "!" + k, &block))
	    end
	}
	ra
    end

    def has_key_r(key)
	select_r { |p,k,v|
	    v.class == Netomata::Node && v.has_key?(key)
	}.collect { |a| a.first }
    end

    def import_file(io,basekey)
	# FIXME add file/line info to error messages
	parent = [basekey]
	io.each_line { |l|
	    l.chomp!			# eliminate trailing newline
	    l.gsub!(/#.*$/, "")		# eliminate trailing comments
	    l.gsub!(/\s*$/, "")		# eliminate trailing whitespace
	    l.gsub!(/^\s*/, "")		# eliminate leading whitespace
	    case l
	    when /^$/ then
		# blank line
		next	# skip blank lines
	    when /^(\S*)\s*(<\s*(\S*))?\s*\{$/
		# templates!devices!(+) {
		# !devices!(+) < templates!devices!(type=router,make=cisco) {
		k = $1
		s = $3
		if (k.include?("(+)")) then
		    # if key ends in "(+)", then make empty node
		    self[parent.last + "!" + k] = Netomata::Node.new
		    # and change key to match newly-created node
		    k.sub!("(+)","(>)")
		end
		if ! s.nil? then
		    # copy subnodes from s
		    self[parent.last + "!" + k].update(self[basekey + "!" + s])
		end
		parent.push(parent.last + "!" + k)
	    when /^([^=\s]*)\s*=\s*(.*)$/
		# make        = cisco
		self[parent.last + "!" + $1] = $2
	    when /^\}$/
		# }
		parent.pop
		if parent.length == 0 then
		    raise "Unmatched '}'"
		end
	    when /^\.include\s+(\S+)$/
		# .include sample.templates.neto
		self.import_file(open($1), basekey)
	    when /^\.table\s+(\S+)$/
		# .table interfaces
		self.import_table(open($1), basekey)
	    else
		raise "Unrecognized line '#{l}'"
	    end
	}
    end

    def import_table(io,basekey) 

	def vsub(a,fields,d,basekey)
	    k = basekey + "!" + a
	    if (m = k.match(/(\([^)]*=)%([^)]*)(\))/)) then
		if ! fields.has_key?(m[2]) then
		    raise "Unknown column name '#{m[2]}'"
		end
		k = m.pre_match + m[1] + d[fields[m[2]]] + m[3] + m.post_match
	    end
	    k
	end

	actions = Array.new
	fields = Dictionary.new
	# FIXME add file/line info to error messages
	io.each_line { |l|
	    l.chomp!			# eliminate trailing newline
	    l.gsub!(/\s*#.*/, "")	# eliminate trailing comments
	    case l
	    when /^$/ then
		# blank line
		next	# skip blank lines
	    when /^\+/ then
		# new-record line
		# + !devices!(hostname=switch-1)!interfaces!(+)
		# + !devices!(hostname=switch-1)!interfaces!(+) < !templates!devices!(make=cisco,type=router)!interfaces!(type=%type)
		if m = l.match(/^\+\s*([^\s<]*)\s*(<\s*(\S*))?$/) then
		    actions << ['+', m[1], m[3]]
		else
		    raise "Malformed '+' line"
		end
	    when /^@/ then
		# per-row action line
		if m = l.match(/^@\s*([^\s=]*)\s*=\s*(.*)$/) then
		    actions << ['@', m[1], m[2]]
		else
		    raise "Malformed '@' line"
		end
	    when /^%/ then
		# field-names line
		# strip leading marker and whitespace
		l.gsub!(/^%\s*/,"")
		# break into fields at tab boundaries
		l.split(/\t+/).each { |f|
		    if fields.has_key?(f) then
			raise "Fields must be uniquely named"
		    end
		    fields[f] = fields.length
		}
	    else
		# must be a data line
		if (fields.nil?) then
		    raise "Fields must be named (via line beginning with '%') before first data line"
		end
		d = l.split(/\t+/)
		if (d.length != fields.length) then
		    raise "Wrong number of fields in line; expected #{fields.length}, got #{d.length}"
		end
		actions.each { |t,f,a|
		    case t
		    when '@'
			k = vsub(a,fields,d,basekey)
			self[k] = d[fields[f]]
		    when '+'
			fk = vsub(f,fields,d,basekey)
			ak = vsub(a,fields,d,basekey)
			if ! self.has_key?(fk) then
			    self[fk] = self[ak].dup
			else 
			    self[fk].update(self[ak])
			end
		    else
			raise "Unknown action '#{t}'"
		    end
		}
	    end
	}
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
		    return "0000001"
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

    ###################################################################
    #### Protected Methods
    ###################################################################

    protected

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
end

# fa = Netomata::Node.new
# fa.import_table(open("vlans"), "!vlans")
# pp(fa)
# pp(fa["!vlans"])
# pp(fa["!vlans!(c_name=IPMI)"])
# pp(fa["!vlans!(c_name=IPMI)!c_id"])
# pp(fa["!vlans!(c_id=48)!c_name"])
# pp(fa["!vlans!(c_activ=maybe)!c_name"])
# pp(fa["!vlans!(c_activ=yes)!c_name"])
