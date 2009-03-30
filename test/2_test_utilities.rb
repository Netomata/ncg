# $Id$
# Copyright (C) 2008, 2009 Netomata, Inc.  All Rights Reserved. 
# Please review accompanying 'LICENSE' file or
# http://www.netomata.com/docs/licenses/ncg for important notices,
# disclaimers, and license terms.

# for ruby-debug, per
# http://blog.nanorails.com/articles/2006/07/14/a-better-rails-debugger-ruby-debug
# SCRIPT_LINES__ = {}

def cwd 
    File.expand_path(File.dirname(__FILE__))
end

if not $LOAD_PATH.include?(cwd) then $LOAD_PATH.unshift(cwd) end
lib = File.expand_path(File.join(File.dirname(__FILE__), '..', 'lib'))
if not $LOAD_PATH.include?(lib) then $LOAD_PATH.unshift(lib) end


require 'netomata'

require 'test/unit'

class UtilitiesTest < Test::Unit::TestCase
    # First set of tests for Netomata::Utilities
    def setup
	$debug = false
	@n = Netomata::Node.new
    end

    def test_buildkey
	assert_equal "!", @n.buildkey("!")
	assert_equal "!a", @n.buildkey("!","a")
	assert_equal "!a!b", @n.buildkey("!","a","b")
	assert_equal "!a!b!c", @n.buildkey("!","a","b","c")
	assert_equal "!a", @n.buildkey("!a")
	assert_equal "!a!b", @n.buildkey("!a","b")
	assert_equal "!a!b!c", @n.buildkey("!a","b","c")
	assert_equal "a", @n.buildkey("a")
	assert_equal "a!b", @n.buildkey("a","b")
	assert_equal "a!b!c", @n.buildkey("a","b","c")
	assert_equal "!a!b!c!d", @n.buildkey("!a!b","c","d")
	assert_equal "a!b!c!d", @n.buildkey("a!b","c","d")
    end

    def test_filename_to_key
	assert_equal "a", @n.filename_to_key("a")
	assert_equal "a!b", @n.filename_to_key("a/b")
	assert_equal "a!b!c", @n.filename_to_key("a/b/c")
	assert_equal "!", @n.filename_to_key("/")
	assert_equal "!a", @n.filename_to_key("/a")
	assert_equal "!a!b", @n.filename_to_key("/a/b")
	assert_equal "!a!b!c", @n.filename_to_key("/a/b/c")
	assert_equal "a!b!(.)!c", @n.filename_to_key("a/b/./c")
	assert_equal "a!.b!(.)!c", @n.filename_to_key("a/.b/./c")
	assert_equal "a!(.)!b!(.)!c", @n.filename_to_key("a/./b/./c")
	assert_equal "a!(..)!b!c", @n.filename_to_key("a/../b/c")
	assert_equal "a!(..)!b!(.)!c", @n.filename_to_key("a/../b/./c")
    end

    def test_ip_union
	assert_equal "10.5.16.34", @n.ip_union("10.5.0.0", "0.0.16.34")
	assert_equal "10.5.17.34", @n.ip_union("10.5.1.0", "0.0.16.34")
    end

    def test_relative_filename
	assert_equal "./d", @n.relative_filename("a", "d")
	assert_equal "/d", @n.relative_filename("/a", "d")
	assert_equal "/a/b/d", @n.relative_filename("/a/b/c", "d")
	assert_equal "/a/b/d/e", @n.relative_filename("/a/b/c", "d/e")
	assert_equal "/d", @n.relative_filename("/a/b/c", "/d")
	assert_equal "/d/e", @n.relative_filename("/a/b/c", "/d/e")
	assert_equal "a/b/d", @n.relative_filename("a/b/c", "d")
	assert_equal "a/b/d/e", @n.relative_filename("a/b/c", "d/e")
	assert_equal "/d", @n.relative_filename("/a/b/c", "/d")
	assert_equal "/d/e", @n.relative_filename("/a/b/c", "/d/e")
    end
end
