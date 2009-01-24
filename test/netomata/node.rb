# $Id$
# Copyright (c) 2008 Netomata, Inc.  All Rights Reserved. 
# Please review accompanying 'LICENSE' file or
# http://www.netomata.com/license_v1 for important notices,
# disclaimers, and license terms (GPL v2.0 or alternative).

# for ruby-debug, per
# http://blog.nanorails.com/articles/2006/07/14/a-better-rails-debugger-ruby-debug
SCRIPT_LINES__ = {}

cwd = File.expand_path(File.dirname(__FILE__))
if not $LOAD_PATH.include?(cwd) then $LOAD_PATH.unshift(cwd) end
lib = File.expand_path(File.join(File.dirname(__FILE__), '..', '..', 'lib'))
if not $LOAD_PATH.include?(lib) then $LOAD_PATH.unshift(lib) end


require 'netomata'

require 'test/unit'
require 'stringio'
require 'yaml'
begin	# rescue block
    require 'ruby-debug'
rescue LoadError
    #
end

# need to crack these open for testing
class Netomata::Node
    public :dictionary_store
    public :dictionary_tuple
    public :node_fetch
    public :selector_to_key
    public :valid?
end

class NodeTest_1 < Test::Unit::TestCase
    # First set of tests for Netomata::Node.
    # This set tests fundamental functionality, _without_ assuming that []
    # and []= handle complex keys (anything with a "!" in it) properly. 
    # If this set of tests fails, none of the other tests can even be set
    # up properly
    def setup
	$debug = false
	@n = Netomata::Node.new
	@n1 = @n.dictionary_store("n1", Netomata::Node.new(@n))
	@n2 = @n.dictionary_store("n2", Netomata::Node.new(@n))

	@n11 = @n1.dictionary_store("n11", Netomata::Node.new(@n1))
	@n12 = @n1.dictionary_store("n12", Netomata::Node.new(@n1))
	@n21 = @n2.dictionary_store("n21", Netomata::Node.new(@n2))
	@n22 = @n2.dictionary_store("n22", Netomata::Node.new(@n2))

	@n111 = @n11.dictionary_store("n111", Netomata::Node.new(@n11))
	@n112 = @n11.dictionary_store("n112", Netomata::Node.new(@n11))
	@n121 = @n12.dictionary_store("n121", Netomata::Node.new(@n12))
	@n122 = @n12.dictionary_store("n122", Netomata::Node.new(@n12))
	@n211 = @n21.dictionary_store("n211", Netomata::Node.new(@n21))
	@n212 = @n21.dictionary_store("n212", Netomata::Node.new(@n21))
	@n221 = @n22.dictionary_store("n221", Netomata::Node.new(@n22))
	@n222 = @n22.dictionary_store("n222", Netomata::Node.new(@n22))

	@k1111 = @n111.dictionary_store("k1111", "v1111")
	@k1112 = @n111.dictionary_store("k1112", "v1112")
	@k1121 = @n112.dictionary_store("k1121", "v1121")
	@k1122 = @n112.dictionary_store("k1122", "v1122")
	@k1211 = @n121.dictionary_store("k1211", "v1211")
	@k1212 = @n121.dictionary_store("k1212", "v1212")
	@k1221 = @n122.dictionary_store("k1221", "v1221")
	@k1222 = @n122.dictionary_store("k1222", "v1222")
	@k2111 = @n211.dictionary_store("k2111", "v2111")
	@k2112 = @n211.dictionary_store("k2112", "v2112")
	@k2121 = @n212.dictionary_store("k2121", "v2121")
	@k2122 = @n212.dictionary_store("k2122", "v2122")
	@k2211 = @n221.dictionary_store("k2211", "v2211")
	@k2212 = @n221.dictionary_store("k2212", "v2212")
	@k2221 = @n222.dictionary_store("k2221", "v2221")
	@k2222 = @n222.dictionary_store("k2222", "v2222")
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

    def test_dictionary_tuple
	assert_equal [@n, "n1"], @n.dictionary_tuple("n1")
	assert_equal [@n, "n1"], @n.dictionary_tuple("!n1")

	$debug = true
	assert_equal [@n1, "n12"], @n.dictionary_tuple("n1!n12")
	assert_equal [@n1, "n12"], @n.dictionary_tuple("!n1!n12")

	assert_equal [@n12, "n121"], @n.dictionary_tuple("n1!n12!n121")
	assert_equal [@n12, "n121"], @n.dictionary_tuple("!n1!n12!n121")

	assert_equal [@n121, "k1212"], @n.dictionary_tuple("n1!n12!n121!k1212")
	assert_equal [@n121, "k1212"], @n.dictionary_tuple("!n1!n12!n121!k1212")

	# n0 doesn't exist, but its parent does, so should return [parent, "n0"]
	assert_equal [@n, "n0"], @n.dictionary_tuple("n0")
	assert_equal [@n, "n0"], @n.dictionary_tuple("!n0")

	# n0 doesn't exist, and we didn't pass create=true, so should return nil
	assert_equal nil, @n.dictionary_tuple("n0!n1")
	assert_equal nil, @n.dictionary_tuple("!n0!n1")

	# n0 doesn't exist, but we pass create=true, so should return tuple.
	# Unfortunately, we don't really have a way to check the validity
	# of the tuple returned, because @n["n0"] gets created during the
	# dictionary_tuple invocation.  We can check that it exists after,
	# though
	assert_not_nil @n.dictionary_tuple("n0!n1",true)
	assert_not_nil @n["n0"]	# check that it exists
	assert_not_nil @n.dictionary_tuple("!n9!n1",true)
	assert_not_nil @n["n9"]	# check that it exists
    end

    def test_node_fetch
	assert_equal "v1122", @n.node_fetch("n1!n11!n112!k1122")
	assert_equal "v1122", @n.node_fetch("!n1!n11!n112!k1122")
	assert_equal "missing leaf",
	    @n.node_fetch("n1!n11!n112!k1124", "missing leaf")
	assert_equal "missing leaf",
	    @n.node_fetch("!n1!n11!n112!k1124", "missing leaf")
	assert_equal "missing node",
	    @n.node_fetch("n1!n11!n114!k1141", "missing node")
	assert_equal "missing node",
	    @n.node_fetch("!n1!n11!n114!k1141", "missing node")
	assert_equal "missing leaf block",
	    @n.node_fetch("n1!n11!n112!k1124") { "missing leaf block" }
	assert_equal "missing leaf block",
	    @n.node_fetch("!n1!n11!n112!k1124") { "missing leaf block" }
	assert_equal "missing node block",
	    @n.node_fetch("n1!n11!n114!k1141") { "missing node block" }
	assert_equal "missing node block",
	    @n.node_fetch("!n1!n11!n114!k1141") { "missing node block" }
	assert_equal nil, @n.node_fetch("n1!n11!n112!k1124")	# missing leaf
	assert_equal nil, @n.node_fetch("n1!n11!n114!k1141")	#  missing node
    end
end

class NodeTest_2 < Test::Unit::TestCase
    def setup
	$debug = false
	@node = Netomata::Node.new
	# debugger
	@node["!n1!k_n1a1"] = "v_n1a1"
	@node["!n1!k_n1a2"] = "v_n1a2"
	@node["!n1!k_n1a3"] = "v_n1a3"
	@node["!n1!k_common_k"] = "v_common_n1"
	@node["!n1!k_common_kv"] = "v_common_kv"
	@node["!n2!k_n2a1"] = "v_n2a1"
	@node["!n2!k_n2a2"] = "v_n2a2"
	@node["!n2!k_n2a3"] = "v_n2a3"
	@node["!n2!k_common_k"] = "v_common_n2"
	@node["!n2!k_common_kv"] = "v_common_kv"
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
    end

    def test_fetch
	assert_equal "v1122", @node.fetch("n1!n11!n112!k1122")
	assert_equal "v1122", @node.fetch("!n1!n11!n112!k1122")
	assert_equal "missing leaf",
	    @node.fetch("n1!n11!n112!k1124", "missing leaf")
	assert_equal "missing leaf",
	    @node.fetch("!n1!n11!n112!k1124", "missing leaf")
	assert_equal "missing node",
	    @node.fetch("n1!n11!n114!k1141", "missing node")
	assert_equal "missing node",
	    @node.fetch("!n1!n11!n114!k1141", "missing node")
	assert_equal "missing leaf block",
	    @node.fetch("n1!n11!n112!k1124") { "missing leaf block" }
	assert_equal "missing leaf block",
	    @node.fetch("!n1!n11!n112!k1124") { "missing leaf block" }
	assert_equal "missing node block",
	    @node.fetch("n1!n11!n114!k1141") { "missing node block" }
	assert_equal "missing node block",
	    @node.fetch("!n1!n11!n114!k1141") { "missing node block" }
	# assert_raise IndexError do
	#     @node.fetch("n1!n11!n112!k1124")	# missing leaf
	# end
	assert_equal nil,  @node.fetch("n1!n11!n112!k1124") # missing leaf
	assert_equal nil, @node.fetch("n1!n11!n114!k1141")	#  missing node
    end

    def test_node_fetch
	assert_equal "v1122", @node.node_fetch("n1!n11!n112!k1122")
	assert_equal "v1122", @node.node_fetch("!n1!n11!n112!k1122")
	assert_equal "missing leaf",
	    @node.node_fetch("n1!n11!n112!k1124", "missing leaf")
	assert_equal "missing leaf",
	    @node.node_fetch("!n1!n11!n112!k1124", "missing leaf")
	assert_equal "missing node",
	    @node.node_fetch("n1!n11!n114!k1141", "missing node")
	assert_equal "missing node",
	    @node.node_fetch("!n1!n11!n114!k1141", "missing node")
	assert_equal "missing leaf block",
	    @node.node_fetch("n1!n11!n112!k1124") { "missing leaf block" }
	assert_equal "missing leaf block",
	    @node.node_fetch("!n1!n11!n112!k1124") { "missing leaf block" }
	assert_equal "missing node block",
	    @node.node_fetch("n1!n11!n114!k1141") { "missing node block" }
	assert_equal "missing node block",
	    @node.node_fetch("!n1!n11!n114!k1141") { "missing node block" }
	# assert_raise IndexError do
	#     @node.node_fetch("n1!n11!n112!k1124")	# missing leaf
	# end
	assert_equal nil,  @node.node_fetch("n1!n11!n112!k1124") # missing leaf
	assert_equal nil, @node.node_fetch("n1!n11!n114!k1141")	#  missing node
    end

    def test_get_root
	assert_same @node, @node["!"]
    end

    def test_get
	assert_equal "v_n1a1", @node["!n1!k_n1a1"]
    end

    def test_reset
	assert_equal "v_n1a1", @node["!n1!k_n1a1"]
	@node["!n1!k_n1a1"] = "new_v_n1a1"
	assert_equal "new_v_n1a1", @node["!n1!k_n1a1"]
    end

    def test_reset_from_middle
	assert_equal "v_n1a1", @node["!n1!k_n1a1"]
	n11 = @node["!n1!n11"]
	n11["!n1!k_n1a1"] = "new_v_n1a1"
	assert_equal "new_v_n1a1", @node["!n1!k_n1a1"]
    end

    def test_set
	assert_equal nil, @node["!n1!k_n1a4"]
	@node["!n1!k_n1a4"] = "new_v_n1a4"
	assert_equal "new_v_n1a4", @node["!n1!k_n1a4"]
    end

    def test_set_from_middle
	assert_equal nil, @node["!n1!k_n1a4"]
	n11 = @node["!n1!n11"]
	n11["!n1!k_n1a4"] = "new_v_n1a4"
	assert_equal "new_v_n1a4", @node["!n1!k_n1a4"]
    end

    def test_selector_plus
	assert_equal nil, @node["!n1!(+)"]
    end

    def test_selector_min
	assert_equal "v_common_n1", @node["!n1!(<)"]
    end

    def test_selector_max
	assert_same @node["!n1!n13"], @node["!n1!(>)"]
    end

    def test_selector_dotdot
	assert_same @node["!n1"], @node["!n1!n11!(..)"]
	assert_same @node["!n1!n11"], @node["!n1!n11!n111!(..)"]
    end

    def test_selector_dotdotdot
	assert_same @node["!n2"], @node["!n1!n11!(...)!n2"]
	assert_same @node["!n1!n13"], @node["!n1!n11!n111!(...)!n13"]
    end

    def test_selector_to_key
	assert_equal "n1", @node.selector_to_key("(<)")
	assert_equal "n2", @node.selector_to_key("(>)")
	assert_equal "n3", @node.selector_to_key("(+)")
	assert_equal "!n1", @node["!n1!n11"].selector_to_key("(..)")
	assert_equal "!n1!n11", @node["!n1!n11!n111"].selector_to_key("(..)")
    end

    def test_selector_criteria
	assert_equal "v_n1a1", @node["!(k_common_k=v_common_n1)!k_n1a1"]
	# for some reason, the following _must_ use do...end not {...}
	assert_raise ArgumentError do
	    @node["!(k_common_kv=v_common_kv)!k_n1a1"]
	end
    end

    def test_append
	@node["!n1!(+)"] = "v_n1a4"
	assert_equal "v_n1a4", @node["!n1!(>)"]
    end

    def test_valid
	assert_equal true, @node.valid?
	# intentionally create a child node with an incorrect parent,
	# to test that the valid? method is working
	@node["!n3"] = Netomata::Node.new(@node["!n1"])
	assert_equal false, @node.valid?
    end

    def test_key
	assert_equal "!", @node.key
	assert_equal "!n1", @node["!n1"].key
	assert_equal "!n1", @node["n1"].key
	assert_equal "!n2", @node["!n2"].key
	assert_equal "!n2", @node["n2"].key
    end

    def test_has_key
	assert_equal true, @node.has_key?("!n1")
	assert_equal true, @node.has_key?("n1")
	assert_equal true, @node.has_key?("!n1!n11")
	assert_equal true, @node.has_key?("n1!n11")
	assert_equal false, @node.has_key?("!n4")
	assert_equal false, @node.has_key?("n4")
	assert_equal false, @node.has_key?("!n1!n14")
	assert_equal false, @node.has_key?("n1!n14")
    end

    def test_keys_having_key
	assert_equal [], @node.keys_having_key("k_uncommon_k")
	assert_equal ["!n1", "!n2"], @node.keys_having_key("k_common_k")
    end

    def test_import_table
	input = StringIO.new <<EOF
# name: interface name
# type: type of interface
# target1: name of device that's connected to this interface on switch-1
# active1: whether interface is active on switch-1 (default "no", not active)
# target2: name of device that's connected to this interface on switch-2
# active2: whether interface is active on switch-2 (default "no", not active)
#
# Note that fields in each row are tab-separated; number of fields must
# match (i.e., each row must have the right number of fields), even if the
# columns don't line up perfectly (because some names are longer than 8
# characters, for instance).  Multiple adjacent tabs are treated the same
# as a single tab (i.e., the field separator is /\t+/), so every field must
# have _something_ in it, even if it's just "-" or "none" or some such.
#
# Note that next non-comment begins with ':', and defines the field names
#
@ name = devices!(hostname=switch-1)!interfaces!(+)!name
@ type = devices!(hostname=switch-1)!interfaces!(name=%name)!type
@ target1 = devices!(hostname=switch-1)!interfaces!(name=%name)!target
@ active1 = devices!(hostname=switch-1)!interfaces!(name=%name)!active
#
@ name = devices!(hostname=switch-2)!interfaces!(+)!name
@ type = devices!(hostname=switch-2)!interfaces!(name=%name)!type
@ target2 = devices!(hostname=switch-2)!interfaces!(name=%name)!target
@ active2 = devices!(hostname=switch-2)!interfaces!(name=%name)!active
#
% name	type	target1		active1	target2		active2
# ----	----	------		-------	------		-------
Gig1/1	host	host-1		yes	host-1		yes
Gig1/2	host	host-2		yes	host-2		yes
Gig1/3	host	host-3		yes	host-3		yes
Gig1/4	host	host-4		yes	host-4		yes
Gig1/5	host	host-5		yes	host-5		yes
Gig1/6	host	host-6		yes	host-6		yes
Gig1/7	host	host-7		yes	host-7		yes
Gig1/8	host	host-8		yes	host-8		yes
Gig1/9	host	host-9		yes	host-9		yes
Gig1/10	host	host-10		yes	host-10		yes
Gig1/11	host	host-11		yes	host-11		yes
Gig1/12	host	host-12		yes	host-12		yes
Gig1/13	host	host-13		no	host-13		no
Gig1/14	host	host-14		no	host-14		no
Gig1/15	host	host-15		no	host-15		no
Gig1/16	host	host-16		no	host-16		no
Gig1/17	host	host-17		no	host-17		no
Gig1/18	host	host-18		no	host-18		no
Gig1/19	host	host-19		no	host-19		no
Gig1/20	host	host-20		no	host-20		no
Gig1/21	host	host-21		no	host-21		no
Gig1/22	host	host-22		no	host-22		no
Gig1/23	host	host-23		no	host-23		no
# Temporarily set up port gig1/24 as management
Gig1/24	host	host-24		yes	host-24		yes
Gig1/25	ipmi	host-1		yes	host-2		yes
Gig1/26	ipmi	host-3		yes	host-4		yes
Gig1/27	ipmi	host-5		yes	host-6		yes
Gig1/28	ipmi	host-7		yes	host-8		yes
Gig1/29	ipmi	host-9		yes	host-10		yes
Gig1/30	ipmi	host-11		yes	host-12		yes
Gig1/31	ipmi	host-13		no	host-14		no
Gig1/32	ipmi	host-15		no	host-16		no
Gig1/33	ipmi	host-17		no	host-18		no
Gig1/34	ipmi	host-19		no	host-20		no
Gig1/35	ipmi	host-21		no	host-22		no
Gig1/36	ipmi	host-23		no	host-24		no
Gig1/37	fwvlan	firewall-1	yes	firewall-2	yes
Gig1/38	fwext	isp-1		yes	isp-2		yes
Gig1/39	loadbal	loadbal-1	yes	loadbal-1	yes
Gig1/40	loadbal	loadbal-2	yes	loadbal-2	yes
Gig1/41	mgmt	firewall-1	yes	firewall-2	yes
Gig1/42	mgmt	loadbal-1	yes	loadbal-2	yes
Gig1/43	mgmt	console		yes	console		yes
Gig1/44	mgmt	pdu-1		yes	pdu-2		yes
Gig1/45	fwvlan	firewall-2	yes	firewall-1	yes
# Temporarily set up port gig1/46 on mgmt VLAN for use by laptops in cage
# Gig1/46	unused	unused	no	unused	no
Gig1/46	mgmt	laptop-1	yes	laptop-2	yes
Gig1/47	trunk	switch-2	yes	switch-1	yes
Gig1/48	trunk	switch-2	yes	switch-1	yes
Ten1/49	unused	unused		no	unused		no
Ten1/50	unused	unused		no	unused		no
EOF

	expected = <<EOF
{"devices"=>
  {"@000000001"=>
    {"hostname"=>"switch-1",
     "interfaces"=>
      {"@000000001"=>
        {"name"=>"Gig1/1",
         "type"=>"host",
         "target"=>"host-1",
         "active"=>"yes"},
       "@000000002"=>
        {"name"=>"Gig1/2",
         "type"=>"host",
         "target"=>"host-2",
         "active"=>"yes"},
       "@000000003"=>
        {"name"=>"Gig1/3",
         "type"=>"host",
         "target"=>"host-3",
         "active"=>"yes"},
       "@000000004"=>
        {"name"=>"Gig1/4",
         "type"=>"host",
         "target"=>"host-4",
         "active"=>"yes"},
       "@000000005"=>
        {"name"=>"Gig1/5",
         "type"=>"host",
         "target"=>"host-5",
         "active"=>"yes"},
       "@000000006"=>
        {"name"=>"Gig1/6",
         "type"=>"host",
         "target"=>"host-6",
         "active"=>"yes"},
       "@000000007"=>
        {"name"=>"Gig1/7",
         "type"=>"host",
         "target"=>"host-7",
         "active"=>"yes"},
       "@000000008"=>
        {"name"=>"Gig1/8",
         "type"=>"host",
         "target"=>"host-8",
         "active"=>"yes"},
       "@000000009"=>
        {"name"=>"Gig1/9",
         "type"=>"host",
         "target"=>"host-9",
         "active"=>"yes"},
       "@000000010"=>
        {"name"=>"Gig1/10",
         "type"=>"host",
         "target"=>"host-10",
         "active"=>"yes"},
       "@000000011"=>
        {"name"=>"Gig1/11",
         "type"=>"host",
         "target"=>"host-11",
         "active"=>"yes"},
       "@000000012"=>
        {"name"=>"Gig1/12",
         "type"=>"host",
         "target"=>"host-12",
         "active"=>"yes"},
       "@000000013"=>
        {"name"=>"Gig1/13",
         "type"=>"host",
         "target"=>"host-13",
         "active"=>"no"},
       "@000000014"=>
        {"name"=>"Gig1/14",
         "type"=>"host",
         "target"=>"host-14",
         "active"=>"no"},
       "@000000015"=>
        {"name"=>"Gig1/15",
         "type"=>"host",
         "target"=>"host-15",
         "active"=>"no"},
       "@000000016"=>
        {"name"=>"Gig1/16",
         "type"=>"host",
         "target"=>"host-16",
         "active"=>"no"},
       "@000000017"=>
        {"name"=>"Gig1/17",
         "type"=>"host",
         "target"=>"host-17",
         "active"=>"no"},
       "@000000018"=>
        {"name"=>"Gig1/18",
         "type"=>"host",
         "target"=>"host-18",
         "active"=>"no"},
       "@000000019"=>
        {"name"=>"Gig1/19",
         "type"=>"host",
         "target"=>"host-19",
         "active"=>"no"},
       "@000000020"=>
        {"name"=>"Gig1/20",
         "type"=>"host",
         "target"=>"host-20",
         "active"=>"no"},
       "@000000021"=>
        {"name"=>"Gig1/21",
         "type"=>"host",
         "target"=>"host-21",
         "active"=>"no"},
       "@000000022"=>
        {"name"=>"Gig1/22",
         "type"=>"host",
         "target"=>"host-22",
         "active"=>"no"},
       "@000000023"=>
        {"name"=>"Gig1/23",
         "type"=>"host",
         "target"=>"host-23",
         "active"=>"no"},
       "@000000024"=>
        {"name"=>"Gig1/24",
         "type"=>"host",
         "target"=>"host-24",
         "active"=>"yes"},
       "@000000025"=>
        {"name"=>"Gig1/25",
         "type"=>"ipmi",
         "target"=>"host-1",
         "active"=>"yes"},
       "@000000026"=>
        {"name"=>"Gig1/26",
         "type"=>"ipmi",
         "target"=>"host-3",
         "active"=>"yes"},
       "@000000027"=>
        {"name"=>"Gig1/27",
         "type"=>"ipmi",
         "target"=>"host-5",
         "active"=>"yes"},
       "@000000028"=>
        {"name"=>"Gig1/28",
         "type"=>"ipmi",
         "target"=>"host-7",
         "active"=>"yes"},
       "@000000029"=>
        {"name"=>"Gig1/29",
         "type"=>"ipmi",
         "target"=>"host-9",
         "active"=>"yes"},
       "@000000030"=>
        {"name"=>"Gig1/30",
         "type"=>"ipmi",
         "target"=>"host-11",
         "active"=>"yes"},
       "@000000031"=>
        {"name"=>"Gig1/31",
         "type"=>"ipmi",
         "target"=>"host-13",
         "active"=>"no"},
       "@000000032"=>
        {"name"=>"Gig1/32",
         "type"=>"ipmi",
         "target"=>"host-15",
         "active"=>"no"},
       "@000000033"=>
        {"name"=>"Gig1/33",
         "type"=>"ipmi",
         "target"=>"host-17",
         "active"=>"no"},
       "@000000034"=>
        {"name"=>"Gig1/34",
         "type"=>"ipmi",
         "target"=>"host-19",
         "active"=>"no"},
       "@000000035"=>
        {"name"=>"Gig1/35",
         "type"=>"ipmi",
         "target"=>"host-21",
         "active"=>"no"},
       "@000000036"=>
        {"name"=>"Gig1/36",
         "type"=>"ipmi",
         "target"=>"host-23",
         "active"=>"no"},
       "@000000037"=>
        {"name"=>"Gig1/37",
         "type"=>"fwvlan",
         "target"=>"firewall-1",
         "active"=>"yes"},
       "@000000038"=>
        {"name"=>"Gig1/38",
         "type"=>"fwext",
         "target"=>"isp-1",
         "active"=>"yes"},
       "@000000039"=>
        {"name"=>"Gig1/39",
         "type"=>"loadbal",
         "target"=>"loadbal-1",
         "active"=>"yes"},
       "@000000040"=>
        {"name"=>"Gig1/40",
         "type"=>"loadbal",
         "target"=>"loadbal-2",
         "active"=>"yes"},
       "@000000041"=>
        {"name"=>"Gig1/41",
         "type"=>"mgmt",
         "target"=>"firewall-1",
         "active"=>"yes"},
       "@000000042"=>
        {"name"=>"Gig1/42",
         "type"=>"mgmt",
         "target"=>"loadbal-1",
         "active"=>"yes"},
       "@000000043"=>
        {"name"=>"Gig1/43",
         "type"=>"mgmt",
         "target"=>"console",
         "active"=>"yes"},
       "@000000044"=>
        {"name"=>"Gig1/44",
         "type"=>"mgmt",
         "target"=>"pdu-1",
         "active"=>"yes"},
       "@000000045"=>
        {"name"=>"Gig1/45",
         "type"=>"fwvlan",
         "target"=>"firewall-2",
         "active"=>"yes"},
       "@000000046"=>
        {"name"=>"Gig1/46",
         "type"=>"mgmt",
         "target"=>"laptop-1",
         "active"=>"yes"},
       "@000000047"=>
        {"name"=>"Gig1/47",
         "type"=>"trunk",
         "target"=>"switch-2",
         "active"=>"yes"},
       "@000000048"=>
        {"name"=>"Gig1/48",
         "type"=>"trunk",
         "target"=>"switch-2",
         "active"=>"yes"},
       "@000000049"=>
        {"name"=>"Ten1/49",
         "type"=>"unused",
         "target"=>"unused",
         "active"=>"no"},
       "@000000050"=>
        {"name"=>"Ten1/50",
         "type"=>"unused",
         "target"=>"unused",
         "active"=>"no"}}},
   "@000000002"=>
    {"hostname"=>"switch-2",
     "interfaces"=>
      {"@000000001"=>
        {"name"=>"Gig1/1",
         "type"=>"host",
         "target"=>"host-1",
         "active"=>"yes"},
       "@000000002"=>
        {"name"=>"Gig1/2",
         "type"=>"host",
         "target"=>"host-2",
         "active"=>"yes"},
       "@000000003"=>
        {"name"=>"Gig1/3",
         "type"=>"host",
         "target"=>"host-3",
         "active"=>"yes"},
       "@000000004"=>
        {"name"=>"Gig1/4",
         "type"=>"host",
         "target"=>"host-4",
         "active"=>"yes"},
       "@000000005"=>
        {"name"=>"Gig1/5",
         "type"=>"host",
         "target"=>"host-5",
         "active"=>"yes"},
       "@000000006"=>
        {"name"=>"Gig1/6",
         "type"=>"host",
         "target"=>"host-6",
         "active"=>"yes"},
       "@000000007"=>
        {"name"=>"Gig1/7",
         "type"=>"host",
         "target"=>"host-7",
         "active"=>"yes"},
       "@000000008"=>
        {"name"=>"Gig1/8",
         "type"=>"host",
         "target"=>"host-8",
         "active"=>"yes"},
       "@000000009"=>
        {"name"=>"Gig1/9",
         "type"=>"host",
         "target"=>"host-9",
         "active"=>"yes"},
       "@000000010"=>
        {"name"=>"Gig1/10",
         "type"=>"host",
         "target"=>"host-10",
         "active"=>"yes"},
       "@000000011"=>
        {"name"=>"Gig1/11",
         "type"=>"host",
         "target"=>"host-11",
         "active"=>"yes"},
       "@000000012"=>
        {"name"=>"Gig1/12",
         "type"=>"host",
         "target"=>"host-12",
         "active"=>"yes"},
       "@000000013"=>
        {"name"=>"Gig1/13",
         "type"=>"host",
         "target"=>"host-13",
         "active"=>"no"},
       "@000000014"=>
        {"name"=>"Gig1/14",
         "type"=>"host",
         "target"=>"host-14",
         "active"=>"no"},
       "@000000015"=>
        {"name"=>"Gig1/15",
         "type"=>"host",
         "target"=>"host-15",
         "active"=>"no"},
       "@000000016"=>
        {"name"=>"Gig1/16",
         "type"=>"host",
         "target"=>"host-16",
         "active"=>"no"},
       "@000000017"=>
        {"name"=>"Gig1/17",
         "type"=>"host",
         "target"=>"host-17",
         "active"=>"no"},
       "@000000018"=>
        {"name"=>"Gig1/18",
         "type"=>"host",
         "target"=>"host-18",
         "active"=>"no"},
       "@000000019"=>
        {"name"=>"Gig1/19",
         "type"=>"host",
         "target"=>"host-19",
         "active"=>"no"},
       "@000000020"=>
        {"name"=>"Gig1/20",
         "type"=>"host",
         "target"=>"host-20",
         "active"=>"no"},
       "@000000021"=>
        {"name"=>"Gig1/21",
         "type"=>"host",
         "target"=>"host-21",
         "active"=>"no"},
       "@000000022"=>
        {"name"=>"Gig1/22",
         "type"=>"host",
         "target"=>"host-22",
         "active"=>"no"},
       "@000000023"=>
        {"name"=>"Gig1/23",
         "type"=>"host",
         "target"=>"host-23",
         "active"=>"no"},
       "@000000024"=>
        {"name"=>"Gig1/24",
         "type"=>"host",
         "target"=>"host-24",
         "active"=>"yes"},
       "@000000025"=>
        {"name"=>"Gig1/25",
         "type"=>"ipmi",
         "target"=>"host-2",
         "active"=>"yes"},
       "@000000026"=>
        {"name"=>"Gig1/26",
         "type"=>"ipmi",
         "target"=>"host-4",
         "active"=>"yes"},
       "@000000027"=>
        {"name"=>"Gig1/27",
         "type"=>"ipmi",
         "target"=>"host-6",
         "active"=>"yes"},
       "@000000028"=>
        {"name"=>"Gig1/28",
         "type"=>"ipmi",
         "target"=>"host-8",
         "active"=>"yes"},
       "@000000029"=>
        {"name"=>"Gig1/29",
         "type"=>"ipmi",
         "target"=>"host-10",
         "active"=>"yes"},
       "@000000030"=>
        {"name"=>"Gig1/30",
         "type"=>"ipmi",
         "target"=>"host-12",
         "active"=>"yes"},
       "@000000031"=>
        {"name"=>"Gig1/31",
         "type"=>"ipmi",
         "target"=>"host-14",
         "active"=>"no"},
       "@000000032"=>
        {"name"=>"Gig1/32",
         "type"=>"ipmi",
         "target"=>"host-16",
         "active"=>"no"},
       "@000000033"=>
        {"name"=>"Gig1/33",
         "type"=>"ipmi",
         "target"=>"host-18",
         "active"=>"no"},
       "@000000034"=>
        {"name"=>"Gig1/34",
         "type"=>"ipmi",
         "target"=>"host-20",
         "active"=>"no"},
       "@000000035"=>
        {"name"=>"Gig1/35",
         "type"=>"ipmi",
         "target"=>"host-22",
         "active"=>"no"},
       "@000000036"=>
        {"name"=>"Gig1/36",
         "type"=>"ipmi",
         "target"=>"host-24",
         "active"=>"no"},
       "@000000037"=>
        {"name"=>"Gig1/37",
         "type"=>"fwvlan",
         "target"=>"firewall-2",
         "active"=>"yes"},
       "@000000038"=>
        {"name"=>"Gig1/38",
         "type"=>"fwext",
         "target"=>"isp-2",
         "active"=>"yes"},
       "@000000039"=>
        {"name"=>"Gig1/39",
         "type"=>"loadbal",
         "target"=>"loadbal-1",
         "active"=>"yes"},
       "@000000040"=>
        {"name"=>"Gig1/40",
         "type"=>"loadbal",
         "target"=>"loadbal-2",
         "active"=>"yes"},
       "@000000041"=>
        {"name"=>"Gig1/41",
         "type"=>"mgmt",
         "target"=>"firewall-2",
         "active"=>"yes"},
       "@000000042"=>
        {"name"=>"Gig1/42",
         "type"=>"mgmt",
         "target"=>"loadbal-2",
         "active"=>"yes"},
       "@000000043"=>
        {"name"=>"Gig1/43",
         "type"=>"mgmt",
         "target"=>"console",
         "active"=>"yes"},
       "@000000044"=>
        {"name"=>"Gig1/44",
         "type"=>"mgmt",
         "target"=>"pdu-2",
         "active"=>"yes"},
       "@000000045"=>
        {"name"=>"Gig1/45",
         "type"=>"fwvlan",
         "target"=>"firewall-1",
         "active"=>"yes"},
       "@000000046"=>
        {"name"=>"Gig1/46",
         "type"=>"mgmt",
         "target"=>"laptop-2",
         "active"=>"yes"},
       "@000000047"=>
        {"name"=>"Gig1/47",
         "type"=>"trunk",
         "target"=>"switch-1",
         "active"=>"yes"},
       "@000000048"=>
        {"name"=>"Gig1/48",
         "type"=>"trunk",
         "target"=>"switch-1",
         "active"=>"yes"},
       "@000000049"=>
        {"name"=>"Ten1/49",
         "type"=>"unused",
         "target"=>"unused",
         "active"=>"no"},
       "@000000050"=>
        {"name"=>"Ten1/50",
         "type"=>"unused",
         "target"=>"unused",
         "active"=>"no"}}}}}
EOF
	n = Netomata::Node.new(nil)
	n["!devices!(+)!hostname"] = "switch-1"
	n["!devices!(+)!hostname"] = "switch-2"
	n.import_table(input, "input")
	assert_equal true, n.valid?
	output = PP::pp(n, StringIO.new)
	assert_equal expected, output.string
    end
end
