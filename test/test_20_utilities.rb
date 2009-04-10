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

class UtilitiesTest_1 < Test::Unit::TestCase
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
	assert_equal "10.5.17.34",
	    @n.ip_union("10.5.0.0", "0.0.17.0", "0.0.0.34")
	assert_equal "10.5.17.34",
	    @n.ip_union("10.0.0.0", "0.5.0.0", "0.0.17.0", "0.0.0.34")
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

class UtilitiesTest_2 < Test::Unit::TestCase
    # Second set of tests for Netomata::Utilities

    include Netomata::Utilities
    include Netomata::Utilities::ClassMethods

    def setup
        $debug = false
        @node = Netomata::Node.new
        @node["!n1!k_n1a1"] = "v_n1a1"
        @node["!n1!k_n1a2"] = "v_n1a2"
        @node["!n1!k_n1a3"] = "v_n1a3"
        @node["!n1!k_common_k"] = "v_common_n1"
        @node["!n1!k_common_kv"] = "v_common_kv"
        @node["!n1!k_common_n!k_common_n_kv"] = "v_common_kv"
        @node["!n2!k_n2a1"] = "v_n2a1"
        @node["!n2!k_n2a2"] = "v_n2a2"
        @node["!n2!k_n2a3"] = "v_n2a3"
        @node["!n2!k_common_k"] = "v_common_n2"
        @node["!n2!k_common_kv"] = "v_common_kv"
        @node["!n2!k_common_n!k_common_n_kv"] = "v_common_kv"
        @node["!n1!n11!k_n11"] = "v_n11"
        @node["!n1!n12!k_n12"] = "v_n12"
        @node["!n1!n13!k_n13"] = "v_n13"
        @node["!n1!n11!n111!k1111"] = "v1111"
        @node["!n1!n11!n111!k1112"] = "v1112"
        @node["!n1!n11!n111!k1113"] = "v1113"
        @node["!n1!n11!n112!k1121"] = "v1121"
        @node["!n1!n11!n112!k1122"] = "v1122"
        @node["!n1!n11!n112!k1123"] = "v1123"
        @node["!n1!n11!n113!k1131"] = "v1131"
        @node["!n1!n11!n113!k1132"] = "v1132"
        @node["!n1!n11!n113!k1133"] = "v1133"
        @node["!n3!(+)"] = "first"
        @node["!n3!(+)"] = "second"
        @node["!n3!(+)"] = "third"
        @node["!n3!(+)"] = "last"
    end

    def test_template_arg
	assert template_arg("@node")
	assert_nothing_raised { template_arg("@node") }
	assert_raise(ArgumentError) { template_arg("@undefined") }
	assert_raise(ArgumentError) { template_arg("@node", String) }
    end

    def test_template_arg_node_key
	assert template_arg_node_key("@node", "!n1!k_n1a3")
	assert_nothing_raised { template_arg_node_key("@node", "!n1!k_n1a3") }

	assert template_arg_node_key("@node", "!n1!k_n1a3", String)
	assert_nothing_raised { 
	    template_arg_node_key("@node", "!n1!k_n1a3", String) }

	assert_raise(ArgumentError) {
	    template_arg_node_key("@undefined", "foo") }

	assert_raise(ArgumentError) {
	    template_arg_node_key("@node", "foo") }

	assert_raise(ArgumentError) {
	    template_arg_node_key("@node", "n1!n11") }
    end
end
