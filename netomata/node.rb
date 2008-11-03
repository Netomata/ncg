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

    include Netomata::Utilities::ClassMethods
    include Netomata::Utilities

    attr_accessor :parent
    attr_writer :root	# caching 'root' method is defined below
    attr_writer :key	# caching 'key' method is defined below

    def initialize(parent=nil)
	self.legitimize(parent)
	# unset key (will be figured out and cached first time key() is called)
	@key = nil
	# invoke super()
	super()
    end

    def initialize_copy(original)
	init_copy(original)
    end

    def init_copy(original)
	# leave these to be set by the dup() that's calling us
	@parent = nil	# because we aren't sure who our parent is
	@root = nil	# because we aren't sure who the root is
	@key = nil	# because we aren't sure who we are
	# make a duplicate of each value
	original.each { |k,v|
	    sk = dictionary_store(k,v.dup)
	    if (sk.is_a?(Netomata::Node)) then
		sk.legitimize(self)
	    end
	}
	self
    end

    def dup
	n = super()
	n.init_copy(self)
	n
    end

    def update(h)
	h.each { |k,v|
	    sk = self[k] = v.dup
	    if (sk.is_a?(Netomata::Node)) then
		sk.legitimize(self)
	    end
	}
	self
    end

    # graft node in as self[key]
    def graft(key,node)
	self[key].update(node)
	self[key].legitimize(self)
    end

    # make self a legitimate child of parent p, and set root and key along
    # the way
    def legitimize(my_parent)
	self.parent = my_parent
	if (my_parent.nil?) then
	    # if parent is nil, then we are root
	    self.root = self
	else
	    self.root = my_parent.root
	end
	# call recursively, to set root all the way down the tree
	# Sometimes we're being called from initialize(), and things aren't
	# set up right yet, causing self.keys to return nil (instead of []),
	# and self.each raises an error (instead of just doing nothing).
	if (! self.keys.nil?) then
	    self.each { |k,v| 
		if (v.is_a?(Netomata::Node)) then
		    v.legitimize(self)
		end
	    }
	end
    end

    # Take a key as argument, untangle it (including any "()" selectors),
    # and return a [node, simple_key] tuple that will access it (such that
    # you can invoke Dictionary methods on the node (for example,
    # node.dictionary_fetch(simple_key)), and they will work. 
    #
    # We need to return the simple key as well as the node, because the
    # key to use with the Dictionary methods might be different than the
    # last part of the argument if the argument included a selector
    # (consider "!a!b!(>)", for example).
    #
    # If optional "create" arg is true, we create any necessary
    # intermediate nodes implied by the key; otherwise,
    # if any intermediate node doesn't already exist, return nil.
    #
    # Note that the element identified by simple_key does NOT need to exist
    # yet (nor is it created if it doesn't, regardless of the "create" arg).
    def dictionary_tuple(key, create=false)
	if (key.nil?) then
	    return nil
	end
	if (key == "!") then
	    # FIXME: not sure this is correct.
	    # 	Maybe should return something like [@root, "(.)"]?
	    # 	But "(.)" won't work as key to Dictionary methods...
	    return [@root, nil]
	end
	if (key[-1..-1] == "!") then
	    # strip trailing "!"
	    key = key.gsub(/!*$/,"")	# this gets us an edited copy of key
	end
	if (! key.include?("!")) then
	    # key does _not_ include a "!", but still might be a "()" selector
	    ks = selector_to_key(key)
	    if (ks != key) then
		# key was a "()" selector, so now we need to get what it
		# resolved to
		return dictionary_tuple(ks, create)
	    else
		# key was not a "()" selector, and has no "!", so it is a
		# simple key that we could use dictionary_fetch() on
		return [self, key]
	    end
	else
	    l,r = key.split("!",2)
	    if (l.empty?) then
		# l == nil means key started with "!", so reference from root
		return @root.dictionary_tuple(r,create)
	    else
		ls = selector_to_key(l,r)
		if (ls != l) then
		    # l was a "()" selector, so now we need to get what it
		    # resolved to
		    return dictionary_tuple(buildkey(ls,r),create)
		else
		    if (dictionary_has_key?(l)) then
			# We have key l, so use it to access r.
			# Since we know we have a key l, there is  no need
			# to pass default args for dictionary_fetch(l)
			if (! dictionary_fetch(l).is_a?(Netomata::Node)) then
			    raise "#{self.key}!#{l} not of class Netomata::Node"
			end
			return dictionary_fetch(l).dictionary_tuple(r,create)
		    else
			# key l doesn't exist; do we create it, or return nil?
			if (create) then
			    # create it, with self as parent
			    ln = Netomata::Node.new(self)
			    dictionary_store(l,ln)
			    return ln.dictionary_tuple(r,create)
			else
			    # don't create it, so return nil
			    return nil
			end
		    end
		end
	    end
	end
    end

    # dictionary_fetch gives us a way to call Dictionary#fetch()
    def dictionary_fetch(*args)
	super_send(:fetch, *args)
    end

    # redefine Netomata::Node#fetch(), to force us to explicitly
    # use either node_fetch() or dictionary_fetch()
    def fetch(*args)
	raise RuntimeError, "Undefined method Netomata::Node.fetch() invoked"
    end

    # redefine [], for convenience
    def [](k)
	node_fetch(k)
    end

    def node_fetch(key, default=nil, &default_block)
	n,k = dictionary_tuple(key,false)
	if (n.nil?) then
	    # Dictionary#fetch, which we're emulating, accepts either
	    # default _or_ default_block, but gives warning if both are
	    # given (and prefers default_block).  So, if default_block
	    # is defined, call that; otherwise, pass default
	    if default_block then
		return default_block.call
	    else
		return default
	    end
	else
	    if k.nil? then
		# if we got back n, but k is nil, then this was a reference
		# to the root node, so just return @root
		return @root
	    else
		if n.dictionary_has_key?(k) then
		    # we know the element has the key, so no need to pass
		    # default or &default_block
		    return n.dictionary_fetch(k)
		else
		    #- return n.dictionary_fetch(k, default, &default_block)
		    # Dictionary#fetch, which we're emulating, accepts either
		    # default _or_ default_block, but gives warning if both are
		    # given (and prefers default_block).  So, if default_block
		    # is defined, call that; otherwise, pass default
		    if default_block then
			return default_block.call
		    else
			return default
		    end
		end
	    end
	end
    end

    # dictionary_store gives us a way to call Dictionary#store()
    def dictionary_store(*args)
	super_send(:store, *args)
    end

    # redefine Netomata::Node#store(), to force us to explicitly
    # use either node_store() or dictionary_store()
    def store(*args)
	raise RuntimeError, "Undefined method Netomata::Node.store() invoked"
    end

    # redefine []=, for convenience
    def []=(k,v)
	node_store(k,v)
    end

    def node_store(key,value)
	n,k = dictionary_tuple(key,true)
	if (n.nil?) then
	    # this shouldn't happen
	    raise IndexError, "node_store(\"#{k}\", ...) failed"
	else
	    if k.nil? then
		# if we got back n, but k is nil, then this was a reference
		# to the root node, so just return @root
		raise IndexError, "Attempt to store nil key in root"
	    else
		return n.dictionary_store(k,value)
	    end
	end
    end

    def keys_r(prefix="")
	ra = []
	self.each { |k,v|
	    ra << k.dup.insert(0,prefix + "!")
	    if v.respond_to?(:keys_r) then
		ra.concat(v.keys_r(buildkey(prefix, k)))
	    end
	}
	ra
    end

    def each_r(prefix="", &block)
	self.each { |k,v|
	    yield(prefix,k,v)
	    if v.respond_to?(:each_r) then
		v.each_r(buildkey(prefix, k), &block)
	    end
	}
	self
    end

    def select_r(prefix="", &block)
	ra = []
	each { |k,v| 
	    ra << [buildkey(prefix, k), v] if yield prefix,k,v
	    if v.respond_to?(:select_r) then
		ra.concat(v.select_r(buildkey(prefix, k), &block))
	    end
	}
	ra
    end

    def keys_having_key(key)
	select_r { |p,k,v|
	    v.is_a?(Netomata::Node) && v.has_key?(key)
	}.collect { |a| a.first }
    end

    def import_file(io,basekey="")
	# FIXME add file/line info to error messages
	pstack = [basekey]
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
		kb = buildkey(pstack.last,k)
		kn,kk = dictionary_tuple(kb,true)
		raise "Unknown key #{k}" if(kn.nil? || kk.nil?)
		if kn.has_key?(kk) then
		    # key already exists, so use it
		    if (! kn[kk].is_a?(Netomata::Node)) then
			raise "Key #{k} already exists, but is not a Netomata::Node"
		    end
		else
		    # key doesn't exist, so create it
		    kn[kk] = Netomata::Node.new(kn)
		end
		# if key ends in "(+)", then dictionary_tuple will
		# have already made an empty node, so
		# change k to match newly-created node (so k can be
		# used later in this method)
		k.sub!("(+)","(>)")
		kb = buildkey(pstack.last,k)
		if ! s.nil? then
		    sb = buildkey(basekey,s)
		    sn,sk = dictionary_tuple(sb,false)
		    debugger if(sn.nil? || sk.nil?)
		    raise "Unknown key #{s}" if(sn.nil? || sk.nil?)
		    # copy subnodes from s
		    raise "Unknown key #{sb}" if sn[sk].nil? 
		    kn.graft(kk,sn[sk])
		end
		pstack.push(kb)
	    when /^([^=\s]*)\s*=\s*(.*)$/
		# make = cisco
		self[buildkey(pstack.last, $1)] = $2
	    when /^\}$/
		# }
		pstack.pop
		if pstack.length == 0 then
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
	self.make_valid
	if (! self.valid?) then
	    raise "Corrupted data structure after import_file"
	end
    end

    def import_table(io,basekey) 

	def vsub(a,fields,d,basekey)
	    k = buildkey(basekey, a)
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
			fkn,fkk = dictionary_tuple(fk,true)
			raise "Unknown key #{fk}" if (fkn.nil? || fkk.nil?)
			ak = vsub(a,fields,d,basekey)
			akn,akk = dictionary_tuple(ak,false)
			raise "Unknown key #{ak}" if (akn.nil? || akk.nil?)
			if (! fkn.has_key?(fkk)) then
			    if akn[akk].nil? then
				raise RuntimeError, "Key #{ak} not found"
			    end
			    fkn[fkk] = Netomata::Node.new(fkn)
			    fkn.graft(fkk, akn[akk])
			    # we don't want to use self[fk] again, because
			    # fk might include a "(+)" or other selector,
			    # and would lead to a different (or nonexistant)
			    # node now that self[fk] has been instantiated.
			else 
			    fkn.graft(fkk,akn[akk])
			end
		    else
			raise "Unknown action '#{t}'"
		    end
		}
	    end
	}
	self.make_valid
	if (! self.valid?) then
	    raise "Corrupted data structure after import_table"
	end
    end

    # Convert a "()" key selector to the appropriate key
    # 	(+): returns new key, successor to current max key
    # 	(>): returns current max key
    # 	(<): returns current min key
    # 	(..): returns parent of current key
    # 	(subkey=value,[subkey2=value ...]): returns key of first subnode
    # 		whose subkey(s) match list of subkey/value criteria
    def selector_to_key(s,rest_of_key=nil)
	m = s.match(/^\((.*)\)$/)
	if m.nil? then
	    # s isn't a "()" selector, so just return s
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
		    return "@000000001"
		else
		    return r.succ
		end
	    when ".."
		return self.parent.key
	    when "..."
		return self.selector_inheritor_to_key(rest_of_key)
	    when /.*=.*/
		r = selector_criteria_to_keys(s)
		if (r.is_a?(Array)) then
		    raise ArgumentError,
		    	"selector \"#{s}\" matches multiple subnodes"
		end
		return r
	    else
		raise ArgumentError, "Unknown selector \"#{s}\""
	    end
	end
    end

    # what is my own root?
    def root
	if (@root.nil?) then
	    if (@parent.nil?) then
		# no parent, so we must be root
		@root = self
	    else
		@root = @parent.root
	    end
	end
	@root
    end

    # what is my own key?
    def key
	if (@key.nil?) then
	    # my key hasn't been cached yet, so figure it out
	    if self.parent.nil? then
		return @key = "!"
	    else
		self.parent.keys.each { |k,v|
		    if self.parent[k] == self then
			return @key = buildkey(self.parent.key,k)
		    end
		}
		raise "Self not found among parent's children!"
	    end
	end
	@key
    end

    # dictionary_has_key? gives us a way to call Dictionary#has_key?()
    def dictionary_has_key?(*args)
	super_send(:has_key?, *args)
    end

    def has_key?(key)
	n,k = dictionary_tuple(key,false)
	if (n.nil?) then
	    return false
	else
	    if k.nil? then
		# if we got back n, but k is nil, then this was a reference
		# to the root node, and everything has a root "key"
		return true
	    else
		return n.dictionary_has_key?(k)
	    end
	end
    end

    # Check this Node's validity by recursively check that all child nodes:
    # 	1) have the correct parent (this node)
    # 	2) have the correct root (same as this node)
    # 	3) have the correct key (this node's key + "!" + child's key)
    def valid?
	self.each { |k,v|
	    child_k = buildkey(self.key,k)
	    if (! self[k].is_a?(Netomata::Node)) then
		# child is not a Netomata::Node, so skip checks
		next
	    elsif (! self[k].parent.equal?(self)) then		# check parent
		debugger if $debug
		return false
	    elsif (! self[k].root.equal?(self.root)) then	# check root
		debugger if $debug
		return false
	    elsif (self[k].key != child_k) then			# check key
		debugger if $debug
		return false
	    elsif (! self[k].valid?) 		# check recursively
		debugger if $debug
		return false
	    end
	}
	return true;
    end
    
    # Make this Node valid by recursively ensuring that all child nodes:
    # 	1) have the correct parent (this node)
    # 	2) have the correct root (same as this node)
    # 	3) have the correct key (this node's key + "!" + child's key)
    def make_valid
	self.each { |k,v|
	    child_k = buildkey(self.key,k)
	    if (! self[k].is_a?(Netomata::Node)) then
		# child is not a Netomata::Node, so skip checks
		next
	    end
	    if (! self[k].parent.equal?(self)) then		# check parent
		puts "# fixing self[\"#{self.key}!#{k}\"].parent" if $debug
		self[k].parent = self
	    end
	    if (! self[k].root.equal?(self.root)) then		# check root
		puts "# fixing self[\"#{self.key}!#{k}\"].root" if $debug
		self[k].root = self.root
	    end
	    if (self[k].key != child_k) then			# check key
		puts "# fixing self[\"#{self.key}!#{k}\"].key" if $debug
		self[k].key = child_k
	    end
	    self[k].make_valid	# check recursively
	}
	return true;
    end

    def describe
	puts "#{self.key}\tself=#{self.object_id}\tparent=#{self.parent.object_id}\troot=#{self.root.object_id}"
	each { |k,v| if (v.is_a?(Netomata::Node)) then v.describe end }
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
	    if (self[k].is_a?(Netomata::Node) && 
		    self[k].node_match_array?(ca)) then
		ra << k
	    end
	}
	case ra.length
	    when 0 then return nil
	    when 1 then return ra[0]
	    else return ra
	end
    end

    # Convert a "(...)" key selector to the key of the closest
    # ancestor that has subkeys that match rest_of_key
    def selector_inheritor_to_key(rest_of_key)
	if self.has_key?(rest_of_key) then
	    # we've got the rest of the key, so return our own key
	    return self.key
	elsif self.parent.nil? then
	    # we're at the root, so nothing has the key
	    return nil
	else
	    # see if our parent has the rest of the key
	    return self.parent.selector_inheritor_to_key(rest_of_key)
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

    ###################################################################
    #### Private Methods
    ###################################################################

    private


end
