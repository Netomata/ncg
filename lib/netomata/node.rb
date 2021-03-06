# $Id$
# Copyright (C) 2008-2010 Netomata, Inc.  All Rights Reserved. 
# Please review accompanying 'LICENSE' file or
# http://www.netomata.com/docs/licenses/ncg for important notices,
# disclaimers, and license terms.
# add methods to the Dictionary class, so that pp() works

# Open the Dictionary class, and add a couple of methods so that pp() works
class Dictionary # :nodoc:

    # add pretty_print method to the Dictionary class, so that pp() works
    def pretty_print(q)
	q.pp_hash self
    end

    # add pretty_print_cycle method to the Dictionary class, so that pp() works
    def pretty_print_cycle(q)
	q.text(empty? ? '{}' : '{...}')
    end
end

# :stopdoc:

# Yes, we're missing an indent level here...  We can't simply open this
# as "class Netomata::Node", because if we do then we're unable to define
# class method Netomata::Node.reset()

# :startdoc:

# The Netomata::Node class extends the Ruby Facets Dictionary class (see
# http://facets.rubyforge.org/apidoc/api/more/classes/Dictionary.html )

class Netomata::Node < Dictionary

    @@iostack = []

    attr_reader :source

    include Netomata::Utilities::ClassMethods
    include Netomata::Utilities

    # Class Methods
    def self.reset() 	# :nodoc:
	@@iostack = []
    end

    # Instance Methods

    # :call-seq:
    #  	new()		-> new_node
    #  	new(parent)	-> new_node
    # 
    # Create a Node. 
    # 
    # * If no _parent_ argument is passed, the Node is assumed to be the root of
    #   a new tree of Nodes.
    # * If a _parent_ argument (which must itself be a Node) is passed, then the
    #   newly-created Node takes that as its parent
    def initialize(parent=nil)
	# It's important to call parent=() rather than setting @parent
	# directly, because parent=() also does a recursive fixup of
	# parent/root/key settings in children.
	self.parent=(parent)
	# unset key (will be figured out and cached first time key() is called)
	self.key_reset
	# record where this node was created from
	if (@@iostack.empty?) then
	    @source = "<root>:0"
	else
	    @source = "#{@@iostack.last.filename}:#{@@iostack.last.lineno}"
	end
	# invoke super()
	super()
    end

    # :call-seq:
    #   node[key] -> value or nil
    #
    # Get _value_ for _key_, or nil if key is not defined
    def [](k)
	node_fetch(k)
    end

    # :call-seq:
    #   node[key]= value -> value
    #
    # Set _value_ for _key_
    def []=(k,v)
	node_store(k,v)
    end

    # :call-seq:
    #   node.affirm?(key) -> true or false
    #
    # Returns true if node has a given _key_ defined,
    # and value of _key_ is affirmative (i.e., is a string
    # that starts with upper- or lower-case "y").
    # Returns false otherwise.
    def affirm?(key)
        if (self.has_key?(key) && (self[key] =~ /^y/i)) then
            return true
        else
            return false
        end
    end

    # :call-seq:
    #	node.dump(io=STDOUT,level=0,show_source=true) -> self
    #
    # Recursively dumps the contents of the node in .neto format to the
    # _io_ handle specified (stdout by default).  
    #
    # _level_ is the indent level to use for this node (0 by default); it
    # is incremented when this method is recursively invoked for sub-nodes,
    # and each level is indented 4 spaces more than the previous level.
    #
    # _show_source_ specifies whether or not to include a comment revealing
    # the source (file name and line number) of each node.

    def dump(io=STDOUT, level=0, show_source=true)
	indent = " " * level * 4
	io.print indent, "# #{self.source}\n" if show_source
	self.each { |k,v|
	    if v.is_a?(Netomata::Node) then
		io.print indent, "#{k} {\n"
		v.dump(io, level+1, show_source)
		io.print indent, "}\n"
	    else
		io.print indent, "#{k} = #{v}\n"
	    end
	}
	self
    end

    # :call-seq:
    # 	node.dup() -> new_node
    #
    # Create a duplicate of the current Node, including recursively duplicating
    # all its children
    def dup
	n = super()
	n.initialize_copy(self)
	n
    end

    # :call-seq:
    #   node.each_by_subkey(k) { |key, subnode| block } -> Array
    #
    # Sorts node's sub-nodes using sort_by_subkey(_k_), then
    # applies _block_ to each resulting [_key_, _subnode_] pair.
    #
    # Returns array of [_key_, _subnode_] pairs (same as sort_by_subkey()).
    def each_by_subkey(k, &block)
	self.sort_by_subkey(k).each &block
    end

    # :call-seq:
    # 	node.each_r(prefix="") { |prefix,k,v| block } -> self
    #
    # Invoke _block_ on each element of _self_ (recursively, if the element is
    # itself a Node).
    #
    # _k_ is appended to _prefix_ for each level of recursion.
    #
    # each_r is typically first called without specifying _prefix_, so
    # that as it recurses, _prefix_ at any given point is the key leading
    # to the current Node.
    #
    # For example
    #   node.each_r { |prefix,k,v| puts "#{prefix}!#{k}" }
    # will print a list of keys of all children of _node_, recursively
    def each_r(prefix="", &block)
	self.each { |k,v|
	    yield(prefix,k,v)
	    if v.respond_to?(:each_r) then
		v.each_r(buildkey(prefix, k), &block)
	    end
	}
	self
    end

    # :call-seq:
    # 	node.equivalent(n) -> true or false
    #
    # Returns true if _n_ is equivalent to _node_, false otherwise.
    # "Equivalent" is defined as:
    # 1. Both nodes have the same set of subsidiary keys (though not
    #    necessarily in the same order)
    # 2. The value of each corresponding key is equivalent; if the value
    #    is itself a Node, it is checked recursively
    # This differs from "==" (which is inherited from Dictionary, our
    # parent class), which also checks that keys are in the same order.
    def equivalent(n2)
	n1 = self
	# check that list of keys is the same (though not necessarily in
	# same order)
	if ! (n1.keys.sort == n2.keys.sort) then
	    return false
	end
	# check each key
	n1.each { |k,v1|
	    v2 = n2[k]
	    if v1.is_a?(Netomata::Node) then
		# if value is another node, check recursively
		return false if ! v1.equivalent(v2)
	    else
		# otherwise, simply check for equality
		return false if ! (v1 == v2)
	    end
	}
	# if we get this far, nodes are equivalent
	return true
    end

    # :call-seq:
    # 	node.fetch(key [, default] )	-> obj
    #   node.fetch(key) {|key| block } 	-> obj
    #
    # Returns the value associated with a given _key_.
    #
    # * If _key_ can be found, returns the value associated with it
    # * If _key_ cannot be found, then
    #   * If called with an optional block, then returns the yield of the block
    #   * If called with an optional _default_ argument, then returns _default_
    #   * Otherwise, returns nil.
    #
    # You should *not* specify *both* a _default_ argument and a block; if
    # you do, you'll get a warning.
    def fetch(key, default=nil, &block)
	node_fetch(key, default, &block)
    end

    # :call-seq:
    # 	node.graft(key,new_node) -> self[key]
    #
    # Graft _new_node_ in as self[_key_]
    def graft(key,node)
	self[key].update(node)
	self[key].parent=(self)
	self[key]
    end

    # :call-seq:
    #   node.has_key?(key) -> true or false
    #
    # Returns true if the given _key_ is defined, false otherwise.
    #
    # _key_ can be a complex key, including with selectors; it will
    # be evaluated relative to the current Node
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

    # :call-seq:
    # 	node.import_file(filenames) -> self
    #
    # Import the contents of a .neto file into this node.
    #
    # See http://www.netomata.com/docs/formats/neto for documentation
    # of the .neto file format
    def import_file(filenames)
	io = Netomata::FileSet.new(filenames)
	@@iostack.push(io)

	$stderr.print "| " * (@@iostack.size - 1),
	    "Reading file(s) #{io.filenames.join(" ")}\n" if $verbose

	pstack = []
	begin	# rescue block
	    io.each_line_cont { |l|
		l.chomp!			# eliminate trailing newline
		l.gsub!(/#.*$/, "") unless 	# eliminate trailing comments,
		    l.match(/\[%.*#.*%\]/)	#   but only if not in [% ... %]
		l.gsub!(/\s*$/, "")		# eliminate trailing whitespace
		l.gsub!(/^\s*/, "")		# eliminate leading whitespace

		if (l.match(/\[%.*%\]/)) then
		    # l contains an ERB template, so process it
		    pn = self[buildkey(pstack.last)]
		    if pn.nil? then
			pn = self 
		    end
		    l = Netomata::Template.new(
			    @@iostack.last.filename,
			    @@iostack.last.lineno,
			    l.gsub(/\[%(.*)%\]/, '<%\1%>')
			 ).result_from_vars({
			    "@target" => pn,
			    "@target_key" => pn.key})
		end

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
		    node(kb)	# create the node, if it doesn't exist already

		    # if key ends in "(+)", then dictionary_tuple will
		    # have already made an empty node, so
		    # change k to match newly-created node (so k can be
		    # used later in this method)
		    k.sub!("(+)","(>)")
		    kb = buildkey(pstack.last,k)
		    if ! s.nil? then
			sn,sk = dictionary_tuple(s,false)
			raise "Unknown key #{s}" if(sn.nil? || sk.nil?)
			# copy subnodes from s
			raise "Unknown key #{s}" if sn[sk].nil? 
			kn.graft(kk,sn[sk])
		    end
		    pstack.push(kb)
		when /^([^\s]*)\s+=\s+(.*)$/
		    # make = cisco
		    # admin_ip = [%= @target["(...)!base_ip"] + "|0.0.16.0" %]
		    kl = $1
		    kr = $2
		    if (["", "-"].include?(kr)) then
			# delete node
			if (self.has_key?(buildkey(pstack.last,kl))) then
			    dn, dk = dictionary_tuple(buildkey(pstack.last,kl))
			    if (! dn.nil?) then
				dn.delete(dk)
			    end
			end
		    else
			# set if not equal to "" or "-"
			self[buildkey(pstack.last, kl)] = kr
		    end
		when /^\}$/
		    # }
		    if pstack.length == 0 then
			raise "Unmatched '}'"
		    end
		    pstack.pop
		when /^include\s+(.+)$/
		    # include sample.templates.neto
		    self[buildkey(pstack.last)].import_file(
			$1.split(" ").collect { |e|
			    relative_filename(io.filename,e)
			}
		    )
		when /^table\s+(.+)$/
		    # table interfaces
		    self[buildkey(pstack.last)].import_table(
			$1.split(" ").collect { |e|
			    relative_filename(io.filename,e)
			}
		    )
		when /^template\s+(\S+)$/
		    # template templates/config.ncg
		    self[buildkey(pstack.last)].import_template(relative_filename(io.filename,$1))
		when /^template_dir\s+(\S+)$/
		    # template_dir sample/templates
		    self[buildkey(pstack.last)].import_template_dir(relative_filename(io.filename,$1))
		else
		    raise "Unrecognized line '#{l}'"
		end
	    }
	rescue => exc
	    fixup_exception(exc,io.filename,io.lineno)
	    raise exc.exception
	end
	io.close
	@@iostack.pop
	make_valid
	if (! self.valid?) then
	    raise "Corrupted data structure after import_file('%{filenames}')"
	end
	self
    end

    # :call-seq:
    # 	node.import_table(filenames) -> self
    #
    # Import the contents of a .neto_table file into this node
    #
    # See http://www.netomata.com/docs/formats/neto_table for documentation
    # of the .neto_table file format.
    def import_table(filenames) 
	# :call-seq:
	# 	var_sub(template,fields,data) -> key
	#
	# Used only by import_table, to do variable substitution of row data
	# into a template of a key.
	#
	# _template_ is a key template, possibly including "(var=%column)"
	#
	# _fields_ is an array of column names.
	#
	# _data_ is an array holding the fields from the current row. 
	#
	# The number of elements in _data_ and _fields_ should be the same
	#
	# For example, given
	#
	# 	template = "(...)!templates!interfaces!(name=%type)"
	# 	fields = ["name", "type", "target", "active"]
	# 	data = ["Gig1/1", "host", "host-1", "yes"]
	#
	# then result would be
	#
	# 	"(...)!templates!interfaces!(name=host)"
	#
	def var_sub(template,fields,data)	# :nodoc:
	    k = buildkey(template)
	    while (m = k.match(/%\{([^}]*)\}/)) do
		if ! fields.has_key?(m[1]) then
		    raise "Unknown column name '#{m[1]}'"
		end
		k = String.new(m.pre_match + data[fields[m[1]]] + m.post_match)
	    end
	    k
	end

	io = Netomata::FileSet.new(filenames)
	@@iostack.push(io)

	$stderr.print "| " * (@@iostack.size - 1),
	    "Reading table(s) #{io.filenames.join(" ")}\n" if $verbose

	actions = Array.new
	fields = Dictionary.new

	begin	# rescue block
	    io.each_line_cont { |l|
		# $stderr.print "\n", "| " * (@@iostack.size - 1) if $verbose
		l.chomp!			# eliminate trailing newline
		l.gsub!(/\s*#.*/, "") unless	# eliminate trailing comments,
			l.match(/\[%.*#.*%\]/)	#   but only if not in [% ... %]
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
		    if m = l.match(/^@\s+(.*?)\s+=\s+(.*)$/) then
			actions << ['@', m[1], m[2]]
		    else
			raise "Malformed '@' line"
		    end
		when /^</ then
		    # per-row import_file line
		    if m = l.match(/^<\s+(\S+)\s+(.*)$/) then
			actions << ['<', m[1], m[2]]
		    else
			raise "Malformed '<' line"
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
			    k = var_sub(f,fields,d)
			    r = var_sub(a,fields,d)
			    r = Netomata::Template.new(
				    @@iostack.last.filename,
				    @@iostack.last.lineno,
				    var_sub(a,fields,d).
				    	gsub(/\[%(.*)%\]/, '<%\1%>')
				 ).result_from_vars({
				    "@target" => self,
				    "@target_key" => self.key})
			    if (["", "-"].include?(r)) then
				# delete node
				dn, dk = dictionary_tuple(k)
				if (! dn.nil?) then
				    dn.delete(dk)
				end
			    else
				# set if not equal to "" or "-"
				self[k] = r
			    end
			when '<'
			    k = var_sub(f,fields,d)
			    r = var_sub(a,fields,d)
			    r = Netomata::Template.new(
				    @@iostack.last.filename,
				    @@iostack.last.lineno,
				    var_sub(a,fields,d).
				    	gsub(/\[%(.*)%\]/, '<%\1%>')
				 ).result_from_vars({
				    "@target" => self,
				    "@target_key" => self.key})
			    self[k].import_file(
					r.split(" ").collect { |e|
					    relative_filename(io.filename,e)
					}
				   )
			when '+'
			    fk = var_sub(f,fields,d)
			    fkn,fkk = dictionary_tuple(fk,true)
			    raise "Unknown key #{fk}" if (fkn.nil? || fkk.nil?)
			    if (! fkn.has_key?(fkk)) then
				fkn[fkk] = Netomata::Node.new(fkn)
			    end
			    if (! a.nil?) then
				# if _a_ is defined, it is a key to a source
				# node that the new node should be a copy of
				ak = var_sub(a,fields,d)
				# look for ak relative to fkn[fkk] (not self)
				akn,akk = fkn[fkk].dictionary_tuple(ak,false)
				if (akn.nil? || akk.nil? || akn[akk].nil?) then
				    raise RuntimeError, "Unknown key #{ak}"
				end
				fkn.graft(fkk,akn[akk])
				# we don't want to use self[fk] again,
				# because fk might include a "(+)" or
				# other selector, and would lead to a
				# different (or nonexistant) node now
				# that self[fk] has been instantiated.
			    end
			else
			    raise "Unknown action '#{t}'"
			end
		    }
		end
	    }
	rescue => exc
	    fixup_exception(exc,io.filename,io.lineno)
	    raise exc.exception
	end
	io.close
	@@iostack.pop
	make_valid
	if (! valid?) then
	    raise "Corrupted data structure after import_table"
	end
	self
    end

    # :call-seq:
    #	node.import_template(filename) -> self
    #
    # Import a .ncg file template into this node.
    #
    # See http://www.netomata.com/docs/formats/ncg for documentation of the
    # .ncg file format.
    #
    # _filename_ should be the name of a file ending in '*.ncg'.
    #
    # The following keys are added to this node:
    # [name] basename of file (i.e., "foo" if _filename_ is "a/foo.ncg")
    # [ncg_template] filename of the file
    def import_template(filename) 
	# clean up filename by removing gratuitous "." elements in path
	template_file = filename.dup
	template_file.gsub!((File::Separator + "." + File::Separator),
			    	File::Separator)
	template_file.sub!(/^\.#{File::Separator}/,"")

	if (! File.file?(template_file)) then
	    raise ArgumentError, "arg must be a valid filename"
	end

	puts "# #{self.key}.import_template(#{template_file})" if $debug

	basename = File.basename(template_file, ".ncg")
	self["name"] = basename
	self["ncg_template"] = template_file
	self
    end

    # :call-seq:
    # 	node.import_template_dir(dirname) -> self
    #
    # Import a tree of templates into the current node.
    #
    # _dirname_ should be the name of a directory.
    #
    # Entries in that directory are added to this node as subnodes
    # according to the following rules:
    # 1. Directory entries with names beginning with a "." are ignored.
    # 2. Regular files named "_filename_.ncg" cause a subnode named "_filename_"
    #    to be added and import_template("_filename_.ncg") to be called to
    #    populate that subnode.
    # 3. Subdirectories named "_subdirname_" cause a subnode named
    #    "_subdirname_" to be added, and import_template_dir("_subdirname_") 
    #    to be called recursively to populate that subnode.
    # 4. All other directory entries are ignored
    def import_template_dir(template_dir) 
	# template_dir should be the name of a directory
	if (! File.directory?(template_dir)) then
	    raise ArgumentError, "template_dir arg must be a directory name"
	end

	template_dir_base = File.basename(template_dir)

	Dir.entries(template_dir).sort.each { |dir_entry|
	    filepath = File.join(template_dir,dir_entry)
	    case dir_entry
	    when "." then next
	    when ".." then next
	    when /^\./ then next	# skip entries beginning with "."
	    when /^(.*)\.ncg/ then
		# process file
		self.node($1).import_template(filepath)
	    else
		if File.directory?(filepath) then
		    # process subdirectory
		    self.node(dir_entry).import_template_dir(filepath)
		end
		# otherwise, skip entry
	    end
	}

	self
    end

    # :call-seq:
    #   node.key -> String
    #
    # Return Node's own key
    #--
    # Key is kept in an oddly-named variable to keep us from accidentally
    # accessing it directly via the obvious "@key" elsewere in this class.
    # It's important to use the self.key() method, rather than accessing
    # it directly via the @... instance variable, because the method figures
    # out what the key should be the first time it is used, and then caches
    # the result for later reuse.
    #++
    def key
	if (@hidden_key.nil?) then
	    # my key hasn't been cached yet, so figure it out
	    #
	    # We use @hidden_parent directly throughout here,
	    # rather than self.parent, for performance reasons
	    if @hidden_parent.nil? then
		return @hidden_key = "!"
	    else
		@hidden_parent.keys.each { |k,v|
		    if @hidden_parent[k] == self then
			return @hidden_key = buildkey(@hidden_parent.key,k)
		    end
		}
		raise "Self not found among parent's children!"
	    end
	end
	@hidden_key
    end

    # :call-seq:
    #   node.keys_having_key(key) -> [k1, ...] or []
    #
    # Recursively checks Node and Node's children for Nodes having _key_
    # defined, and returns an array of the keys of matching Nodes
    #
    # Returns an empty array if there are no Nodes with matching _key_ defined
    def keys_having_key(key)
	r = []
	if self.has_key?(key) then
	    r << self.key
	end
	r += select_r { |p,k,v|
	    v.is_a?(Netomata::Node) && v.has_key?(key)
	}.collect { |a| a.first }
	r
    end

    # :call-seq:
    #   node.keys_r -> [key, ...] or []
    #
    # Returns an array of the keys of all the children of _node_, recursively
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

    # :call-seq:
    #   node.parent -> Node or nil
    #
    # Returns parent of current Node.  Returns nil if Node has no parent
    # (i.e., if it's the root node)
    #--
    # Parent is kept in an oddly-named variable to keep us from accidentally
    # setting it directly via @parent elsewere in this class.  It's generally
    # important to use the parent=() method because the method does some
    # recursive fixup of root and key in children when a node's parent is
    # changed.
    #++
    def parent
	@hidden_parent
    end

    # :call-seq:
    #   node.parent=(my_parent) -> my_parent
    #
    # Sets the parent of current Node.
    # Makes self a legitimate child of _my_parent_, recursively
    # fixing parent, root, and key of self and any child Nodes as needed
    def parent=(my_parent)
	@hidden_parent = my_parent
	if (my_parent.nil?) then
	    # if parent is nil, then we are root
	    @hidden_root = self
	else
	    @hidden_root = my_parent.root
	end
	# call recursively, to set root all the way down the tree
	# Sometimes we're being called from initialize(), and things aren't
	# set up right yet, causing self.keys to return nil (instead of []),
	# and self.each raises an error (instead of just doing nothing).
	if (! self.keys.nil?) then
	    self.each { |k,v| 
		if (v.is_a?(Netomata::Node)) then
		    v.parent=(self)
		end
	    }
	end
	@hidden_parent
    end

    # :call-seq:
    #   node.root -> Node
    #
    # Get root Node (most distant ancestor) of current Node
    #--
    # Root is kept in an oddly-named variable to keep us from accidentally
    # accessing it from elsewhere in this class directly via the obvious
    # "@root". It's important to use the self.key() method because the method
    # figures out what the key should be the first time it is used, and then
    # caches the result for later reuse.
    #++
    def root
	if (@hidden_root.nil?) then
	    # sets @hidden_root, if it isn't already set
	    if (@hidden_parent.nil?) then
		# no parent, so we must be root
		@hidden_root = self
	    else
		@hidden_root = @hidden_parent.root
	    end
	end
	@hidden_root
    end

    # :call-seq:
    #	node.select_r { |prefix,k,v| block_returning_true_or_false } -> [] or [[k,v], ...]
    #
    # Recursively goes through all this Node's children, and
    # returns a new array consisting of [key,value] pairs for which the
    # block returns true.  Returns an empty array if no children match.
    #
    # _k_ is appended to _prefix_ for each level of recursion.
    #
    # select_r is typically first called without specifying _prefix_, so
    # that as it recurses, _prefix_ at any given point is the key leading
    # to the current Node.
    #
    # For example
    #   node.select_r { |prefix,k,v| 
    # 	    v.is_a?(Netomata::Node) && v.has_key?("foo")
    # 	}
    # will return a recursively-constructed list of child Nodes and
    # their keys which themselves have a key named "foo" defined
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

    # :call-seq:
    #   node.sort_by_subkey(k) -> Array
    #   node.sort_by_subkey(k) { |a,b| block } -> Array
    #
    # Returns sub-nodes of node as an array of [_key_, _value_] tuples,
    # sorted by value of _k_ in each sub-node.  
    # * If optional _block_ is given, it is used to compare the values being
    #   sorted, to determine sort order  
    #   * Just like the <=> operator, the block should take 2 arguments,
    #     and should return -1, 0, or 1 depending on whether the
    #     first argument is less than, equal to, or greater than the
    #     second argument. 
    #   * The comparison block should deal gracefully with _nil_ arguments,
    #     since a _nil_ argument will be passed in for a sub-node doesn't
    #     have a value for _k_.
    # * If no _block_ is given, then the "compare_parts" method is used to
    #   compare the values being sorted, to determine sort order.
    #   * compare_parts treats a nil argument as greater than any other
    #     argument, so if a given sub-node doesn't have a key _k_, that
    #     sub-node will be sorted to the end of the list.
    #
    # For example, given the following nodes and sub-nodes:
    # * n["a"] = { "name" => "FastEthernet1" }
    # * n["b"] = { "name" => "FastEthernet10" }
    # * n["c"] = { "name" => "FastEthernet2" }
    # * n["d"] = { "alias" => "FastEthernet3" }
    # * n["e"] = { "name" => "FastEthernet4" }
    # Then n.sort_by_subkey("name") will return the following array of tuples:
    # * [
    #   * ["a", {"name"=>"FastEthernet1"}],
    #   * ["c", {"name"=>"FastEthernet2"}],
    #   * ["e", {"name"=>"FastEthernet4"}],
    #   * ["b", {"name"=>"FastEthernet10"}]
    #   * ["d", {"alias"=>"FastEthernet3"}]
    # * ]
    def sort_by_subkey(k, &block)
	self.sort { |a,b|
	    # a and b will both be [key, node] tuples (2-element Arrays).
	    # Since we want to sort by a sub-key, we need to reach into
	    # the node, which is the second element of each tuple; thus
	    # the references to a[1] and b[1] are to the nodes themselves,
	    # and a[1][k] and b[1][k] accesses the value of the named
	    # key within each node.

	    if block_given? then
		yield(a[1][k], b[1][k])
	    else 
		# use compare_parts() by default, if no comparator given
		compare_parts(a[1][k], b[1][k])
	    end
	}
    end

    # :call-seq:
    # 	node.store(key,value) -> value
    #
    # Stores _value_ at _key_ relative to the current Node
    #
    # _key_ can be a complex key
    def store(k,v)
	node_store(k,v)
    end

    # Adds a copy of the contents of _h_ to self, just like Hash#update(),
    # * Entries for keys that didn't already exist are created, and values
    #   are copied from _h_
    # * Entries for keys that did already exist are replaced with values
    #   copied from _h_
    #
    # _h_ should be a Hash, Dictionary, or Node
    #
    # :call-seq:
    #	node.update(h) -> self
    #
    def update(h)
	h.each { |k,v|
	    sk = self[k] = v.dup
	    if (sk.is_a?(Netomata::Node)) then
		sk.parent=(self)
	    end
	}
	self
    end

    ###################################################################
    #### Protected Methods
    ###################################################################

    protected

    # :call-seq:
    # 	node.dictionary_fetch(simple_key [, default] ) 		-> obj
    #   node.dictionary_fetch(simple_key) {|simple_key| block } -> obj
    #
    # Returns the value associated with a given _simple_key_.
    #
    # _simple_key_ *must* be a simple key (no "!", no "( ... )" selectors,
    # etc.), suitable for use with Dictionary or Hash methods.
    #
    # * If _simple_key_ can be found, returns the value associated with it
    # * If _simple_key_ cannot be found, then
    #   * If called with an optional block, then returns the yield of the block
    #   * If called with an optional _default_ argument, then returns _default_
    #   * Otherwise, returns nil.
    #
    # You should *not* specify *both* a _default_ argument and a block; if
    # you do, you'll get a warning.
    #
    # dictionary_fetch is a way to call Dictionary#fetch() explicitly on a
    # Node, without getting tangled up in a morass of super() calls.
    #--
    # Dictionary#fetch(), in turn, just calls Hash#fetch().
    #++
    def dictionary_fetch(*args)
	raise ArgumentError, "must specify key" if args.length == 0
	raise ArgumentError, "must be a simple key" unless simple_key?(args[0])
	super_send(:fetch, *args)
    end

    # :call-seq:
    # 	node.dictionary_has_key?(key) -> true or false
    #
    # Call Dictionary#has_key?(_key_)
    #
    # _key_ *must* be a simple key (no "!", no "( ... )" selectors, 
    # etc.), suitable for use with Dictionary or Hash methods.
    def dictionary_has_key?(*args)
	raise ArgumentError, "must specify key" if args.length == 0
	raise ArgumentError, "must be a simple key" unless simple_key?(args[0])
	super_send(:has_key?, *args)
    end

    # :call-seq:
    # 	node.dictionary_store(key,value) -> value
    #
    # Call Dictionary#store(_key_, _value_)
    #
    # _key_ *must* be a simple key (no "!", no "( ... )" selectors, 
    # etc.), suitable for use with Dictionary or Hash methods.
    def dictionary_store(*args)
	raise ArgumentError, "must specify key" if args.length == 0
	raise ArgumentError, "must be a simple key" unless simple_key?(args[0])
	super_send(:store, *args)
    end

    # :call-seq:
    #   node.dictionary_tuple(key, [create=false]) -> [parent_node, simple_key]
    #
    # Takes a complex _key_ as argument, decodes it (including any "()"
    # selectors), and returns a tuple (a 2-element Array) of
    # [_parent_node_, _simple_key_]
    # that will access whatever _key_ refers to.  The elements of the tuple
    # returned are such that you can invoke Dictionary methods on
    # _parent_node_ using _simple_key_, and expect them to work; for example:
    #   node_fetch(complex_key) => value
    # is equivalent to
    #   parent_node,simple_key = dictionary_tuple(complex_key)
    #   parent_node.dictionary_fetch(simple_key) => value
    #
    # The method returns the _simple_key_ as well as the _parent_node_,
    # both for convenience of the caller and because the simple key for
    # use with Dictionary methods might be different from the last part
    # of the argument if the argument included a selector
    # (consider an argument of "!a!b!(>)", for example).
    #
    # If the optional _create_ arg is true, then any necessary
    # intermediate nodes implied by _key_ are created; otherwise,
    # if any necessary intermediate node doesn't already exist, returns nil.
    #
    # Note that the element of _parent_node_ identified by _simple_key_
    # does NOT need to exist yet (nor is it created if it doesn't,
    # regardless of the "create" arg).
    def dictionary_tuple(key, create=false)
	if (key.nil?) then
	    return nil
	end
	if (key == "!") then
	    # Perhaps should return something like [self.root, "(.)"],
	    # 	but "(.)" won't work as key to Dictionary methods...
	    return [self.root, nil]
	end
	if (key[-1..-1] == "!") then
	    # strip trailing "!"
	    key = key.gsub(/!*$/,"")	# this gets us an edited copy of key
	end
	if (! key.include?("!")) then
	    # key does _not_ include a "!", but still might be a "()" selector
	    ks = selector_to_key(key)
	    if (key.match(/^\(.*\)$/)) then
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
		return self.root.dictionary_tuple(r,create)
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

    # :call-seq:
    # 	node.initialize_copy(original) -> self
    #
    # Initializes self as a copy of _original_ node, by duplicating each
    # subelement of _original_ in turn. If a subelement is itself a Node, uses
    # parent=() on the copy of the subelement to fix up its parent
    # reference to point to self (rather than whatever parent
    # the original had before)
    def initialize_copy(original)
	# leave these to be set by the dup() that's calling us
	@hidden_parent = nil	# because we aren't sure who our parent is
	@hidden_root = nil	# because we aren't sure who the root is
	@hidden_key = nil	# because we aren't sure who we are
	# make a duplicate of each value
	original.each { |k,v|
	    sk = dictionary_store(k,v.dup)
	    if (sk.is_a?(Netomata::Node)) then
		sk.parent=(self)
	    end
	}
	# Note source of original in copy
	@source << " < " << original.source
	self
    end

    #--
    # for some reason, this needs to be made explicit, or Ruby blows chunks;
    # simply having the method defined (just above) in the "protected" section
    # of this file should be sufficient, but isn't for some reason.  Ruby bug?
    #++

    protected :initialize_copy

    # :call-seq:
    #   node.key_reset() -> nil
    #
    # Resets the key of the current node. 
    #--
    # We can't really trust what somebody else tells us our key should be, so
    # this gives us a way to reset the current node's key to nil, so that
    # self.key() will figure out (and cache) what it should be the next
    # time something attempts to access it.
    #++
    def key_reset
	@hidden_key = nil
    end

    # :call-seq:
    # 	node.make_valid() -> true
    #
    # Makes this Node valid by recursively ensuring that all child nodes:
    # 1. have the correct parent (this node)
    # 2. have the correct root (same as this node)
    # 3. have the correct key (this node's key + "!" + child's key)
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
		self[k].key_reset
	    end
	    self[k].make_valid	# check recursively
	}
	return true;
    end

    # :call-seq:
    #   n.node(key) -> Node
    #
    # Returns the Node for key, creating the Node if necessary.
    # If n[key] already exists, but isn't a Node, raises an error.
    def node(key)
	kn,kk = dictionary_tuple(key,true)
	raise "Unknown key #{key}" if kn.nil?
	if kk.nil? then
	    # if we got back a kn, but kk is nil, then was self-reference to kn
	    return kn
	end
	if kn.has_key?(kk) then
	    # key already exists, so use it
	    if (! kn[kk].is_a?(Netomata::Node)) then
		raise "Key #{k} already exists, but is not a Netomata::Node"
	    end
	else
	    # key doesn't exist, so create it
	    kn[kk] = Netomata::Node.new(kn)
	end
	kn[kk]
    end

    # :call-seq:
    #   node.node_match_array?([[k,v] [, ...]]) -> true or false
    #
    # Checks to see whether current node matches an array of [key,value] pairs
    #
    # All keys must be defined, and all values must match the corresponding key
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

    # :call-seq:
    #   node.selector_inheritor_to_key(rest_of_key) -> key or nil
    #
    # Converts a "(...)" key selector to the key of the closest
    # ancestor that has subkeys that match _rest_of_key_
    def selector_inheritor_to_key(rest_of_key)
	if self.has_key?(rest_of_key) then
	    # we've got the rest of the key, so return our own key
	    return self.key
	elsif @hidden_parent.nil? then
	    # we're at the root, so nothing has the key
	    return nil
	else
	    # see if our parent has the rest of the key
	    return @hidden_parent.selector_inheritor_to_key(rest_of_key)
	end
    end

    # :call-seq:
    #   node.valid? -> true or false
    #
    # Checks current Node's validity by recursively check that all child nodes:
    # 1. have the correct parent (this node)
    # 2. have the correct root (same as this node)
    # 3. have the correct key (this node's key + "!" + child's key)
    def valid?
	self.each { |k,v|
	    child_k = buildkey(self.key,k)
	    if (! self[k].is_a?(Netomata::Node)) then
		# child is not a Netomata::Node, so skip checks
		next
	    elsif (! self[k].parent.equal?(self)) then	# check parent
		return false
	    elsif (! self[k].root.equal?(self.root)) then # check root
		return false
	    elsif (self[k].key != child_k) then		# check key
		return false
	    elsif (! self[k].valid?) 			# check recursively
		return false
	    end
	}
	return true;
    end

    ###################################################################
    #### Private Methods
    ###################################################################

    private

    # :call-seq:
    # 	node.fixup_exception(exception,filename,lineno) -> exception
    #
    # Fixes the backtrace in the passed _exception_ to include nested source
    # files.
    #--
    # Because of the way exception handling works (i.e., "rescue" blocks
    # in nested invocations of import_file/import_table get called in
    # sequence), we should only modify the backtrace on the first (deepest)
    # exception and call to this method.  We figure out whether this is
    # that "first exception" by checking to see whether the filename and
    # lineno arguments match those of the deepest entry on the @@iostack 
    # class variable.
    #++
    def fixup_exception(exc,filename,lineno)
	# push all file:line onto backtrace
	if ((! @@iostack.empty?) &&
	      (@@iostack.last.filename == filename) &&
	      (@@iostack.last.lineno == lineno)) then
	    # ... but only if we're at the bottom of the exception stack.
	    # Otherwise, the whole file:line stack gets
	    # duplicated onto the backtrace as the rescue stack unwinds
	    st = @@iostack.collect { |t|
		"#{t.filename}:#{t.lineno}"
	    }
	    bt = exc.backtrace.dup
	    bt.shift	# throw away the first element
	    bt = st.reverse + bt
	    exc.set_backtrace(bt)
	end
	exc
    end

    # :call-seq:
    # 	node.metadata_fetch(req) -> string
    #
    # Returns requested metadata.  Valid requests are:
    # [FILENAME] returns name of config file currently being read
    # [BASENAME] returns basename of config file currently being read
    # [DIRNAME] returns dirname of config file currently being read
    def metadata_fetch(req)
	case req
	when "FILENAME" then
	    return @@iostack.last.filename
	when "BASENAME" then
	    return File.basename(@@iostack.last.filename)
	when "DIRNAME" then
	    return File.dirname(@@iostack.last.filename)
	else
	    raise ArgumentError, "Unknown metadata request '{#{req}}'"
	end
    end

    # :call-seq:
    # 	node.node_fetch(key [, default] )	-> obj
    #   node.node_fetch(key) {|key| block } 	-> obj
    #
    # Returns the value associated with a given _key_.
    #
    # * If _key_ is nil, returns nil
    # * If _key_ can be found, returns the value associated with it
    # * If _key_ cannot be found, then
    #   * If called with an optional block, then returns the yield of the block
    #   * If called with an optional _default_ argument, then returns _default_
    #   * Otherwise, returns nil.
    #
    # You should *not* specify *both* a _default_ argument and a block; if
    # you do, you'll get a warning.
    def node_fetch(key, default=nil, &default_block)
	if (key.nil?) then
	    return nil
	end
	if (key.match(/^\{(.*)\}$/)) then
	    # key is a "{foo}" metadata request, so return that
	    return metadata_fetch($1)
	end
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
		# to the root node, so just return self.root
		return self.root
	    else
		if n.dictionary_has_key?(k) then
		    # we know the element has the key, so no need to pass
		    # default or &default_block
		    return n.dictionary_fetch(k)
		else
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

    # :call-seq:
    # 	node.node_store(key,value) -> value
    #
    # Stores _value_ at _key_ relative to the current Node
    #
    # _key_ can be a complex key
    def node_store(key,value)
	n,k = dictionary_tuple(key,true)
	if (n.nil?) then
	    # this shouldn't happen
	    raise IndexError, "node_store(\"#{k}\", ...) failed"
	else
	    if k.nil? then
		# if we got back n, but k is nil, then this was a reference
		# to the root node
		raise IndexError, "Attempt to store nil key in root"
	    else
		return n.dictionary_store(k,value)
	    end
	end
    end

    # :call-seq:
    #   node.selector_criteria_to_keys(criteria) -> [key, ...] or [] 
    #
    # Converts a "(subkey=value,[subkey2=value2 ...])" key selector criteria
    # to an array of the keys of the subnodes whose subkey(s) match the list
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

    # :call-seq:
    #   node.selector_to_key(selector, [rest_of_key=nil]) -> key
    #
    # Converts a "()" key selector to the appropriate key
    # * (+) returns successor to current max anonymous key 
    # * (>) returns current max anonymous key
    # * (<) returns current min anonymous key
    # * (.) returns current key
    # * (..) returns parent of current key
    # * (...) returns nearest ancestor of current key which has
    #   _rest_of_key_ defined
    # * (subkey=value,[subkey2=value ...]) returns key of first subnode
    #   whose subkey(s) match list of subkey/value criteria
    #
    # Anonymous keys match the pattern /^@[0-9]+$/
    def selector_to_key(s,rest_of_key=nil)
	m = s.match(/^\((.*)\)$/)
	if m.nil? then
	    # s isn't a "()" selector, so just return s
	    return s
	else
	    case m[1]
	    when ">"
		return self.keys.grep(/^@[0-9]+$/).max
	    when "<"
		return self.keys.grep(/^@[0-9]+$/).min
	    when "+"
	    	r = self.keys.grep(/^@[0-9]+$/).max
		if (r.nil?) then
		    return "@000000001"
		else
		    return r.succ
		end
	    when "."
		return self.key
	    when ".."
		return @hidden_parent.key
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

    # :call-seq:
    # 	node.simple_key?(key) -> true or false
    #
    # Returns true if _key_ is a simple key (i.e., suitable for passing to
    # Dictionary methods), or false otherwise.
    def simple_key?(k)
	if $paranoid then
	    return false if ! k.is_a?(String)
	    return false if k.include?("!")
	    return false if k.include?("(")
	    return false if k.include?("{")
	end
	return true
    end

end	# class Netomata:;Node
