# $Id$
# Copyright (C) 2008, 2009 Netomata, Inc.  All Rights Reserved. 
# Please review accompanying 'LICENSE' file or
# http://www.netomata.com/docs/licenses/ncg for important notices,
# disclaimers, and license terms.

# for ruby-debug, per
# http://blog.nanorails.com/articles/2006/07/14/a-better-rails-debugger-ruby-debug
SCRIPT_LINES__ = {} unless defined?(SCRIPT_LINES__)

def cwd 
    File.expand_path(File.dirname(__FILE__))
end

if not $LOAD_PATH.include?(cwd) then $LOAD_PATH.unshift(cwd) end
lib = File.expand_path(File.join(File.dirname(__FILE__), '..', 'lib'))
if not $LOAD_PATH.include?(lib) then $LOAD_PATH.unshift(lib) end

require 'netomata'

require 'test/unit'
require 'tempfile'

class Regressions_Test < Test::Unit::TestCase
    # Tests for regressions of various bugs
    def setup
	$debug = false
	$paranoid = true
	@testfiles = File.join(cwd,"files","cases")
	@n = Netomata::Node.new
    end

    # https://netomata.fogbugz.com/default.asp?54
    def test_case54
	@n.import_file(File.join(@testfiles, "case54/case54.neto"))
	
	# dump to a file. 
	#
	# To recreate baseline file, use following
	# line instead of Tempfile line:
	# t = File.new("/tmp/case54.dump", "w")
	t = Tempfile.new("ncg_test.case54.neto", "/tmp")
	@n.dump(t,0,false)
	t.close

	# check that the dumped file matches what it should
	assert FileUtils.compare_file(t.path,
				      File.join(@testfiles,
						"case54/case54.dump")
				     )
    end

    # https://netomata.fogbugz.com/default.asp?48
    #
    # Statements like this in .neto files:
    #
    #     !vlans!(id=3)!vlan_ip = 172.24.1.0
    #
    # don't work; you get
    #
    #     ERROR(ArgumentError): must be a simple key at testbed.neto:17

    def test_case48
	@n.import_file(File.join(@testfiles, "case48/case48.neto"))
	
	# dump to a file. 
	#
	# To recreate baseline file, use following
	# line instead of Tempfile line:
	# t = File.new("/tmp/case48.dump", "w")
	t = Tempfile.new("ncg_test.case48.neto", "/tmp")
	@n.dump(t,0,false)
	t.close

	# check that the dumped file matches what it should
	assert FileUtils.compare_file(t.path,
				      File.join(@testfiles,
						"case48/case48.dump")
				     )
    end
    
end
