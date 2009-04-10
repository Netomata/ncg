# $Id$
# Copyright (C) 2008, 2009 Netomata, Inc.  All Rights Reserved. 
# Please review accompanying 'LICENSE' file or
# http://www.netomata.com/docs/licenses/ncg for important notices,
# disclaimers, and license terms.
# add methods to the Dictionary class, so that pp() works

class Netomata::FileSet

    attr_reader :filenames

    # :call-seq:
    #   new(list)	-> new_fileset
    #
    # Create a FileSet.
    #
    # _list_ can be a String (in which case it is interpreted as a single
    # filename or glob pattern) or an Array (in which case it must be an
    # Array of Strings which are each filenames or glob patterns).
    # _list_ is expanded into an internal array of actual filenames,
    # which are then treated as if they were one big concatenated file by
    # the instance methods in this class.
    def initialize(list)
	@filenames = []
	@current_index = nil
	@current_file = nil

	def expand_filenames(p)		# :nodoc:
	    raise ArgumentError, "expected String" unless p.is_a?(String)
	    if (p == "-") then
		# special case for STDIN
		return ["<STDIN>"]
	    end
	    Dir.glob(p, File::FNM_PATHNAME).select { |fn|
		File.file?(fn)
	    }.sort
	end

	if list.is_a?(String) then
	    @filenames.concat(expand_filenames(list))
	    if (@filenames.size == 0) then
		raise RuntimeError, "No file(s) found matching '#{list}'"
	    end
	elsif list.is_a?(Array) then
	    list.each do |l|
		raise ArgumentError, "expected String" unless l.is_a?(String)
		@filenames.concat(expand_filenames(l))
	    end
	    if (@filenames.size == 0) then
		raise RuntimeError,
		    "No file(s) found matching '#{list.join(" ")}'"
	    end
	else
	    raise ArgumentError, "expected String or Array"
	end
	open_next
	self
    end

    # :call-seq:
    #   close() -> nil
    #
    # Closes the FileSet.
    def close
	if (! @current_file.nil?) then
	    @current_file.close
	    @current_file = nil
	    @current_index = nil
	end
	nil
    end

    # :call-seq:
    #   lineno() -> integer or nil
    #
    # Returns the line number of the current file within the fileset,
    # just like IO::lineno would.  
    def lineno
	if (! @current_file.nil?) then
	    @current_file.lineno
	else
	    nil
	end
    end
    
    # :call-seq:
    #   lineno=(int) -> integer or nil
    #
    # Sets the line number of the current file within the fileset,
    # just like IO::lineno= would.  This does *not* change the read
    # pointer within the file; it merely changes the line number that
    # would be reported by lineno()
    def lineno=(arg)
	if (! @current_file.nil?) then
	    @current_file.lineno=(arg)
	else
	    nil
	end
    end

    # :call-seq:
    #   filename() -> String or nil
    #
    # Returns the name of the current file within the FileSet.
    def filename
	if (! @current_index.nil?) then
	    @filenames[@current_index]
	else
	    nil
	end
    end

    # :call-seq:
    #   each_line(sep = $/) {|line| block} -> self or nil
    #
    # Executes the block for each line in each file in the FileSet, treating
    # them as if they were one big file that had been concatenated together.
    # At any given time, code in the block can call filename() or lineno()
    # to determine the name of the file currently being read or the line
    # number within that file.
    #
    # Returns nil if there are no files to read.
    def each_line(sep = $/)
	if (! @current_index.nil?) then
	    begin
		@current_file.each_line(sep) { |x|
		    yield(x)
		}
	    end while open_next
	else
	    nil
	end
    end

    # :call-seq:
    #   each_line_cont(sep = $/) {|line| block} -> self or nil
    #
    # Executes the block for each line in each file in the FileSet, while
    # recognizing '\' at the end of a line to signify that the next line
    # should be treated as part of the current line (just like
    # in a shell script).  All files in the FileSet are treated
    # as if they were one big file that had been concatenated together.
    # At any given time, code in the block can call filename() or lineno()
    # to determine the name of the file currently being read or the line
    # number within that file.
    #
    # Kudos to http://markmail.org/message/4qnc4rd7oowvlc7g
    def each_line_cont(sep = $/)
	hold = ''
	skip = 0
	self.each_line(sep) { |x|
	    if x =~ /\\#{sep}/ then
		hold << x.chomp("\\#{sep}")
		self.lineno=(self.lineno - 1)
		skip += 1
	    elsif hold.empty? 
		yield(x)
	    else
		yield(hold+x)
		self.lineno=(self.lineno + skip)
		skip = 0
		hold = ''
	    end
	}
    end

    ###################################################################
    #### Private Methods
    ###################################################################

    private

    # Opens the next file in the FileSet (first closing the current file,
    # if needed).  Returns true if there is more data to read in the FileSet,
    # false otherwise (i.e., if there are no more files in the FileSet)
    def open_next 	# :nodoc:
	if @current_index.nil? then
	    @current_index = 0
	else
	    @current_index = @current_index + 1
	end
	if (@current_index < @filenames.size) then
	    if (! @current_file.nil?) then
		@current_file.close
	    end
	    if (@filenames[@current_index] == "<STDIN>") then
		@current_file = STDIN
	    else
		@current_file = File.open(@filenames[@current_index])
	    end
	    true
	else
	    false
	end
    end
end
