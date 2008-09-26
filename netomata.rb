require 'rubygems'
require 'facets'
require 'facets/dictionary'
require 'pp'

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
	attr_accessor :type, :id

	def initialize(type, id)
	    @type = type
	    @id = id
	    super()
	end

	def [](k)
	    #DEBUG puts "[](\"#{k}\")"
	    if (k.include?("!")) then
		l,r = k.split("!",2)
		#DEBUG puts "l,r = [\"#{l}\",\"#{r}\"]"
		if (l.empty?) then
		    #DEBUG puts "[r]"
		    self[r]
		else
		    #DEBUG puts "[l][r]"
		    super(l)[r]
		end
	    else
		#DEBUG puts "[k]"
		super(k)
	    end
	end

	def []=(k,v)
	    super(k,v)
	end
    end

    class Util
	class FileArray < Array

	    def initialize(io) 
		super()		# initialize the underlying Array object
		io.each_line { |l|
		    l.chomp!			# eliminate trailing newline
		    l.gsub!(/\s*#.*/, "")	# eliminate trailing comments
		    case l
		    when /^$/ then
			next	# skip blank lines
		    when /^#/ then
			next	# skip comments
		    when /^:/ then
			l.gsub!(/^:\s*/,"")	# strip leading marker and whitespace
			@keys = l.split(/\t+/)
		    else
			d = l.split(/\t+/)
			if (d.length != @keys.length) then
			    raise "Wrong number of fields in line; expected #{@keys.length}, got #{d.length}"
			end
			self.push(Dictionary.new)
			@keys.each { |k|
			    v = d.shift
			    # if the string value is really an integer
			    # (determined by converting it to an integer
			    # and then back to a string, and comparing that
			    # to the original string), then push the value
			    # as an integer; otherwise, push it as a string
			    if (v.to_i.to_s == v) then
				v = v.to_i
			    end
			    self.last[k.intern] = v
			}
		    end

		}
	    end
	end
    end
end
