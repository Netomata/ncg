# for ruby-debug, per
# http://blog.nanorails.com/articles/2006/07/14/a-better-rails-debugger-ruby-debug
SCRIPT_LINES__ = {}

cwd = File.expand_path(File.dirname(__FILE__))
if not $LOAD_PATH.include?(cwd) then $LOAD_PATH.unshift(cwd) end
lib = File.expand_path(File.join(File.dirname(__FILE__), '..', '..'))
if not $LOAD_PATH.include?(lib) then $LOAD_PATH.unshift(lib) end


require File.join(File.dirname(__FILE__), '..', '..', 'netomata')
require File.join(File.dirname(__FILE__), '..', '..', 'netomata', 'node')
require 'test/unit'
require 'ruby-debug'
require 'stringio'
require 'yaml'

class NodeTest < Test::Unit::TestCase
    def setup
	@node = Netomata::Node.new
	@node["!n1"] = Netomata::Node.new
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
    end

    def test_get
	assert_equal "v_n1a1", @node["!n1!k_n1a1"]
    end

    def test_reset
	assert_equal "v_n1a1", @node["!n1!k_n1a1"]
	@node["!n1!k_n1a1"] = "new_v_n1a1"
	assert_equal "new_v_n1a1", @node["!n1!k_n1a1"]
    end

    def test_set
	assert_equal nil, @node["!n1!k_n1a4"]
	@node["!n1!k_n1a4"] = "new_v_n1a4"
	assert_equal "new_v_n1a4", @node["!n1!k_n1a4"]
    end

    def test_selector_plus
	assert_equal nil, @node["!n1!(+)"]
    end

    def test_selector_min
	assert_equal "v_common_n1", @node["!n1!(<)"]
    end

    def test_selector_max
	assert_equal "v_n1a3", @node["!n1!(>)"]
    end

    def test_selector_to_key
	assert_equal "n1", @node.selector_to_key("(<)")
	assert_equal "n2", @node.selector_to_key("(>)")
	assert_equal "n3", @node.selector_to_key("(+)")
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

    def test_import
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
@ name = !devices!(hostname=switch-1)!interfaces!(+)!name
@ type = !devices!(hostname=switch-1)!interfaces!(name=%name)!type
@ target1 = !devices!(hostname=switch-1)!interfaces!(name=%name)!target
@ active1 = !devices!(hostname=switch-1)!interfaces!(name=%name)!active
#
@ name = !devices!(hostname=switch-2)!interfaces!(+)!name
@ type = !devices!(hostname=switch-2)!interfaces!(name=%name)!type
@ target2 = !devices!(hostname=switch-2)!interfaces!(name=%name)!target
@ active2 = !devices!(hostname=switch-2)!interfaces!(name=%name)!active
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
{"xyzzy"=>
  {"devices"=>
    {"0000001"=>
      {"hostname"=>"switch-1",
       "interfaces"=>
        {"0000001"=>
          {"name"=>"Gig1/1",
           "type"=>"host",
           "target"=>"host-1",
           "active"=>"yes"},
         "0000002"=>
          {"name"=>"Gig1/2",
           "type"=>"host",
           "target"=>"host-2",
           "active"=>"yes"},
         "0000003"=>
          {"name"=>"Gig1/3",
           "type"=>"host",
           "target"=>"host-3",
           "active"=>"yes"},
         "0000004"=>
          {"name"=>"Gig1/4",
           "type"=>"host",
           "target"=>"host-4",
           "active"=>"yes"},
         "0000005"=>
          {"name"=>"Gig1/5",
           "type"=>"host",
           "target"=>"host-5",
           "active"=>"yes"},
         "0000006"=>
          {"name"=>"Gig1/6",
           "type"=>"host",
           "target"=>"host-6",
           "active"=>"yes"},
         "0000007"=>
          {"name"=>"Gig1/7",
           "type"=>"host",
           "target"=>"host-7",
           "active"=>"yes"},
         "0000008"=>
          {"name"=>"Gig1/8",
           "type"=>"host",
           "target"=>"host-8",
           "active"=>"yes"},
         "0000009"=>
          {"name"=>"Gig1/9",
           "type"=>"host",
           "target"=>"host-9",
           "active"=>"yes"},
         "0000010"=>
          {"name"=>"Gig1/10",
           "type"=>"host",
           "target"=>"host-10",
           "active"=>"yes"},
         "0000011"=>
          {"name"=>"Gig1/11",
           "type"=>"host",
           "target"=>"host-11",
           "active"=>"yes"},
         "0000012"=>
          {"name"=>"Gig1/12",
           "type"=>"host",
           "target"=>"host-12",
           "active"=>"yes"},
         "0000013"=>
          {"name"=>"Gig1/13",
           "type"=>"host",
           "target"=>"host-13",
           "active"=>"no"},
         "0000014"=>
          {"name"=>"Gig1/14",
           "type"=>"host",
           "target"=>"host-14",
           "active"=>"no"},
         "0000015"=>
          {"name"=>"Gig1/15",
           "type"=>"host",
           "target"=>"host-15",
           "active"=>"no"},
         "0000016"=>
          {"name"=>"Gig1/16",
           "type"=>"host",
           "target"=>"host-16",
           "active"=>"no"},
         "0000017"=>
          {"name"=>"Gig1/17",
           "type"=>"host",
           "target"=>"host-17",
           "active"=>"no"},
         "0000018"=>
          {"name"=>"Gig1/18",
           "type"=>"host",
           "target"=>"host-18",
           "active"=>"no"},
         "0000019"=>
          {"name"=>"Gig1/19",
           "type"=>"host",
           "target"=>"host-19",
           "active"=>"no"},
         "0000020"=>
          {"name"=>"Gig1/20",
           "type"=>"host",
           "target"=>"host-20",
           "active"=>"no"},
         "0000021"=>
          {"name"=>"Gig1/21",
           "type"=>"host",
           "target"=>"host-21",
           "active"=>"no"},
         "0000022"=>
          {"name"=>"Gig1/22",
           "type"=>"host",
           "target"=>"host-22",
           "active"=>"no"},
         "0000023"=>
          {"name"=>"Gig1/23",
           "type"=>"host",
           "target"=>"host-23",
           "active"=>"no"},
         "0000024"=>
          {"name"=>"Gig1/24",
           "type"=>"host",
           "target"=>"host-24",
           "active"=>"yes"},
         "0000025"=>
          {"name"=>"Gig1/25",
           "type"=>"ipmi",
           "target"=>"host-1",
           "active"=>"yes"},
         "0000026"=>
          {"name"=>"Gig1/26",
           "type"=>"ipmi",
           "target"=>"host-3",
           "active"=>"yes"},
         "0000027"=>
          {"name"=>"Gig1/27",
           "type"=>"ipmi",
           "target"=>"host-5",
           "active"=>"yes"},
         "0000028"=>
          {"name"=>"Gig1/28",
           "type"=>"ipmi",
           "target"=>"host-7",
           "active"=>"yes"},
         "0000029"=>
          {"name"=>"Gig1/29",
           "type"=>"ipmi",
           "target"=>"host-9",
           "active"=>"yes"},
         "0000030"=>
          {"name"=>"Gig1/30",
           "type"=>"ipmi",
           "target"=>"host-11",
           "active"=>"yes"},
         "0000031"=>
          {"name"=>"Gig1/31",
           "type"=>"ipmi",
           "target"=>"host-13",
           "active"=>"no"},
         "0000032"=>
          {"name"=>"Gig1/32",
           "type"=>"ipmi",
           "target"=>"host-15",
           "active"=>"no"},
         "0000033"=>
          {"name"=>"Gig1/33",
           "type"=>"ipmi",
           "target"=>"host-17",
           "active"=>"no"},
         "0000034"=>
          {"name"=>"Gig1/34",
           "type"=>"ipmi",
           "target"=>"host-19",
           "active"=>"no"},
         "0000035"=>
          {"name"=>"Gig1/35",
           "type"=>"ipmi",
           "target"=>"host-21",
           "active"=>"no"},
         "0000036"=>
          {"name"=>"Gig1/36",
           "type"=>"ipmi",
           "target"=>"host-23",
           "active"=>"no"},
         "0000037"=>
          {"name"=>"Gig1/37",
           "type"=>"fwvlan",
           "target"=>"firewall-1",
           "active"=>"yes"},
         "0000038"=>
          {"name"=>"Gig1/38",
           "type"=>"fwext",
           "target"=>"isp-1",
           "active"=>"yes"},
         "0000039"=>
          {"name"=>"Gig1/39",
           "type"=>"loadbal",
           "target"=>"loadbal-1",
           "active"=>"yes"},
         "0000040"=>
          {"name"=>"Gig1/40",
           "type"=>"loadbal",
           "target"=>"loadbal-2",
           "active"=>"yes"},
         "0000041"=>
          {"name"=>"Gig1/41",
           "type"=>"mgmt",
           "target"=>"firewall-1",
           "active"=>"yes"},
         "0000042"=>
          {"name"=>"Gig1/42",
           "type"=>"mgmt",
           "target"=>"loadbal-1",
           "active"=>"yes"},
         "0000043"=>
          {"name"=>"Gig1/43",
           "type"=>"mgmt",
           "target"=>"console",
           "active"=>"yes"},
         "0000044"=>
          {"name"=>"Gig1/44",
           "type"=>"mgmt",
           "target"=>"pdu-1",
           "active"=>"yes"},
         "0000045"=>
          {"name"=>"Gig1/45",
           "type"=>"fwvlan",
           "target"=>"firewall-2",
           "active"=>"yes"},
         "0000046"=>
          {"name"=>"Gig1/46",
           "type"=>"mgmt",
           "target"=>"laptop-1",
           "active"=>"yes"},
         "0000047"=>
          {"name"=>"Gig1/47",
           "type"=>"trunk",
           "target"=>"switch-2",
           "active"=>"yes"},
         "0000048"=>
          {"name"=>"Gig1/48",
           "type"=>"trunk",
           "target"=>"switch-2",
           "active"=>"yes"},
         "0000049"=>
          {"name"=>"Ten1/49",
           "type"=>"unused",
           "target"=>"unused",
           "active"=>"no"},
         "0000050"=>
          {"name"=>"Ten1/50",
           "type"=>"unused",
           "target"=>"unused",
           "active"=>"no"}}},
     "0000002"=>
      {"hostname"=>"switch-2",
       "interfaces"=>
        {"0000001"=>
          {"name"=>"Gig1/1",
           "type"=>"host",
           "target"=>"host-1",
           "active"=>"yes"},
         "0000002"=>
          {"name"=>"Gig1/2",
           "type"=>"host",
           "target"=>"host-2",
           "active"=>"yes"},
         "0000003"=>
          {"name"=>"Gig1/3",
           "type"=>"host",
           "target"=>"host-3",
           "active"=>"yes"},
         "0000004"=>
          {"name"=>"Gig1/4",
           "type"=>"host",
           "target"=>"host-4",
           "active"=>"yes"},
         "0000005"=>
          {"name"=>"Gig1/5",
           "type"=>"host",
           "target"=>"host-5",
           "active"=>"yes"},
         "0000006"=>
          {"name"=>"Gig1/6",
           "type"=>"host",
           "target"=>"host-6",
           "active"=>"yes"},
         "0000007"=>
          {"name"=>"Gig1/7",
           "type"=>"host",
           "target"=>"host-7",
           "active"=>"yes"},
         "0000008"=>
          {"name"=>"Gig1/8",
           "type"=>"host",
           "target"=>"host-8",
           "active"=>"yes"},
         "0000009"=>
          {"name"=>"Gig1/9",
           "type"=>"host",
           "target"=>"host-9",
           "active"=>"yes"},
         "0000010"=>
          {"name"=>"Gig1/10",
           "type"=>"host",
           "target"=>"host-10",
           "active"=>"yes"},
         "0000011"=>
          {"name"=>"Gig1/11",
           "type"=>"host",
           "target"=>"host-11",
           "active"=>"yes"},
         "0000012"=>
          {"name"=>"Gig1/12",
           "type"=>"host",
           "target"=>"host-12",
           "active"=>"yes"},
         "0000013"=>
          {"name"=>"Gig1/13",
           "type"=>"host",
           "target"=>"host-13",
           "active"=>"no"},
         "0000014"=>
          {"name"=>"Gig1/14",
           "type"=>"host",
           "target"=>"host-14",
           "active"=>"no"},
         "0000015"=>
          {"name"=>"Gig1/15",
           "type"=>"host",
           "target"=>"host-15",
           "active"=>"no"},
         "0000016"=>
          {"name"=>"Gig1/16",
           "type"=>"host",
           "target"=>"host-16",
           "active"=>"no"},
         "0000017"=>
          {"name"=>"Gig1/17",
           "type"=>"host",
           "target"=>"host-17",
           "active"=>"no"},
         "0000018"=>
          {"name"=>"Gig1/18",
           "type"=>"host",
           "target"=>"host-18",
           "active"=>"no"},
         "0000019"=>
          {"name"=>"Gig1/19",
           "type"=>"host",
           "target"=>"host-19",
           "active"=>"no"},
         "0000020"=>
          {"name"=>"Gig1/20",
           "type"=>"host",
           "target"=>"host-20",
           "active"=>"no"},
         "0000021"=>
          {"name"=>"Gig1/21",
           "type"=>"host",
           "target"=>"host-21",
           "active"=>"no"},
         "0000022"=>
          {"name"=>"Gig1/22",
           "type"=>"host",
           "target"=>"host-22",
           "active"=>"no"},
         "0000023"=>
          {"name"=>"Gig1/23",
           "type"=>"host",
           "target"=>"host-23",
           "active"=>"no"},
         "0000024"=>
          {"name"=>"Gig1/24",
           "type"=>"host",
           "target"=>"host-24",
           "active"=>"yes"},
         "0000025"=>
          {"name"=>"Gig1/25",
           "type"=>"ipmi",
           "target"=>"host-2",
           "active"=>"yes"},
         "0000026"=>
          {"name"=>"Gig1/26",
           "type"=>"ipmi",
           "target"=>"host-4",
           "active"=>"yes"},
         "0000027"=>
          {"name"=>"Gig1/27",
           "type"=>"ipmi",
           "target"=>"host-6",
           "active"=>"yes"},
         "0000028"=>
          {"name"=>"Gig1/28",
           "type"=>"ipmi",
           "target"=>"host-8",
           "active"=>"yes"},
         "0000029"=>
          {"name"=>"Gig1/29",
           "type"=>"ipmi",
           "target"=>"host-10",
           "active"=>"yes"},
         "0000030"=>
          {"name"=>"Gig1/30",
           "type"=>"ipmi",
           "target"=>"host-12",
           "active"=>"yes"},
         "0000031"=>
          {"name"=>"Gig1/31",
           "type"=>"ipmi",
           "target"=>"host-14",
           "active"=>"no"},
         "0000032"=>
          {"name"=>"Gig1/32",
           "type"=>"ipmi",
           "target"=>"host-16",
           "active"=>"no"},
         "0000033"=>
          {"name"=>"Gig1/33",
           "type"=>"ipmi",
           "target"=>"host-18",
           "active"=>"no"},
         "0000034"=>
          {"name"=>"Gig1/34",
           "type"=>"ipmi",
           "target"=>"host-20",
           "active"=>"no"},
         "0000035"=>
          {"name"=>"Gig1/35",
           "type"=>"ipmi",
           "target"=>"host-22",
           "active"=>"no"},
         "0000036"=>
          {"name"=>"Gig1/36",
           "type"=>"ipmi",
           "target"=>"host-24",
           "active"=>"no"},
         "0000037"=>
          {"name"=>"Gig1/37",
           "type"=>"fwvlan",
           "target"=>"firewall-2",
           "active"=>"yes"},
         "0000038"=>
          {"name"=>"Gig1/38",
           "type"=>"fwext",
           "target"=>"isp-2",
           "active"=>"yes"},
         "0000039"=>
          {"name"=>"Gig1/39",
           "type"=>"loadbal",
           "target"=>"loadbal-1",
           "active"=>"yes"},
         "0000040"=>
          {"name"=>"Gig1/40",
           "type"=>"loadbal",
           "target"=>"loadbal-2",
           "active"=>"yes"},
         "0000041"=>
          {"name"=>"Gig1/41",
           "type"=>"mgmt",
           "target"=>"firewall-2",
           "active"=>"yes"},
         "0000042"=>
          {"name"=>"Gig1/42",
           "type"=>"mgmt",
           "target"=>"loadbal-2",
           "active"=>"yes"},
         "0000043"=>
          {"name"=>"Gig1/43",
           "type"=>"mgmt",
           "target"=>"console",
           "active"=>"yes"},
         "0000044"=>
          {"name"=>"Gig1/44",
           "type"=>"mgmt",
           "target"=>"pdu-2",
           "active"=>"yes"},
         "0000045"=>
          {"name"=>"Gig1/45",
           "type"=>"fwvlan",
           "target"=>"firewall-1",
           "active"=>"yes"},
         "0000046"=>
          {"name"=>"Gig1/46",
           "type"=>"mgmt",
           "target"=>"laptop-2",
           "active"=>"yes"},
         "0000047"=>
          {"name"=>"Gig1/47",
           "type"=>"trunk",
           "target"=>"switch-1",
           "active"=>"yes"},
         "0000048"=>
          {"name"=>"Gig1/48",
           "type"=>"trunk",
           "target"=>"switch-1",
           "active"=>"yes"},
         "0000049"=>
          {"name"=>"Ten1/49",
           "type"=>"unused",
           "target"=>"unused",
           "active"=>"no"},
         "0000050"=>
          {"name"=>"Ten1/50",
           "type"=>"unused",
           "target"=>"unused",
           "active"=>"no"}}}}}}
EOF
	n = Netomata::Node.new
	n["!xyzzy!devices!(+)!hostname"] = "switch-1"
	n["!xyzzy!devices!(+)!hostname"] = "switch-2"
	n.import(input, "!xyzzy")
	output = PP::pp(n, StringIO.new)
	assert_equal expected, output.string
    end
end
