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

class Netomata_IPAddr_Test < Test::Unit::TestCase

    def test_exceptions
	# all of these should throw exceptions (out of range, etc.)
	assert_raise(ArgumentError) { Netomata::IPAddr.netmask_as_bits(-1) }
	assert_raise(ArgumentError) { Netomata::IPAddr.netmask_as_bits(129) }
	assert_raise(ArgumentError) { Netomata::IPAddr.netmask_as_bits(nil) }
	assert_raise(IPAddr::InvalidAddressError) {
	    Netomata::IPAddr.netmask_as_bits("foo")
	}
    end

    def test_netmask
	# The following table lists all possible netmasks expressed as:
	# 	number of significant bits
	# 	CIDR notation
	# 	dotted-quad notation (IPv4)
	# 	colon-separated hex (IPv6)
	# This is used to check all permutations of all methods in this class

	[
	    [0, "0.0.0.0", "0000:0000:0000:0000:0000:0000:0000:0000"],
	    [1, "128.0.0.0", "8000:0000:0000:0000:0000:0000:0000:0000"],
	    [2, "192.0.0.0", "c000:0000:0000:0000:0000:0000:0000:0000"],
	    [3, "224.0.0.0", "e000:0000:0000:0000:0000:0000:0000:0000"],
	    [4, "240.0.0.0", "f000:0000:0000:0000:0000:0000:0000:0000"],
	    [5, "248.0.0.0", "f800:0000:0000:0000:0000:0000:0000:0000"],
	    [6, "252.0.0.0", "fc00:0000:0000:0000:0000:0000:0000:0000"],
	    [7, "254.0.0.0", "fe00:0000:0000:0000:0000:0000:0000:0000"],
	    [8, "255.0.0.0", "ff00:0000:0000:0000:0000:0000:0000:0000"],
	    [9, "255.128.0.0", "ff80:0000:0000:0000:0000:0000:0000:0000"],
	    [10, "255.192.0.0", "ffc0:0000:0000:0000:0000:0000:0000:0000"],
	    [11, "255.224.0.0", "ffe0:0000:0000:0000:0000:0000:0000:0000"],
	    [12, "255.240.0.0", "fff0:0000:0000:0000:0000:0000:0000:0000"],
	    [13, "255.248.0.0", "fff8:0000:0000:0000:0000:0000:0000:0000"],
	    [14, "255.252.0.0", "fffc:0000:0000:0000:0000:0000:0000:0000"],
	    [15, "255.254.0.0", "fffe:0000:0000:0000:0000:0000:0000:0000"],
	    [16, "255.255.0.0", "ffff:0000:0000:0000:0000:0000:0000:0000"],
	    [17, "255.255.128.0", "ffff:8000:0000:0000:0000:0000:0000:0000"],
	    [18, "255.255.192.0", "ffff:c000:0000:0000:0000:0000:0000:0000"],
	    [19, "255.255.224.0", "ffff:e000:0000:0000:0000:0000:0000:0000"],
	    [20, "255.255.240.0", "ffff:f000:0000:0000:0000:0000:0000:0000"],
	    [21, "255.255.248.0", "ffff:f800:0000:0000:0000:0000:0000:0000"],
	    [22, "255.255.252.0", "ffff:fc00:0000:0000:0000:0000:0000:0000"],
	    [23, "255.255.254.0", "ffff:fe00:0000:0000:0000:0000:0000:0000"],
	    [24, "255.255.255.0", "ffff:ff00:0000:0000:0000:0000:0000:0000"],
	    [25, "255.255.255.128", "ffff:ff80:0000:0000:0000:0000:0000:0000"],
	    [26, "255.255.255.192", "ffff:ffc0:0000:0000:0000:0000:0000:0000"],
	    [27, "255.255.255.224", "ffff:ffe0:0000:0000:0000:0000:0000:0000"],
	    [28, "255.255.255.240", "ffff:fff0:0000:0000:0000:0000:0000:0000"],
	    [29, "255.255.255.248", "ffff:fff8:0000:0000:0000:0000:0000:0000"],
	    [30, "255.255.255.252", "ffff:fffc:0000:0000:0000:0000:0000:0000"],
	    [31, "255.255.255.254", "ffff:fffe:0000:0000:0000:0000:0000:0000"],
	    [32, "255.255.255.255", "ffff:ffff:0000:0000:0000:0000:0000:0000"],
	    [33, nil, "ffff:ffff:8000:0000:0000:0000:0000:0000"],
	    [34, nil, "ffff:ffff:c000:0000:0000:0000:0000:0000"],
	    [35, nil, "ffff:ffff:e000:0000:0000:0000:0000:0000"],
	    [36, nil, "ffff:ffff:f000:0000:0000:0000:0000:0000"],
	    [37, nil, "ffff:ffff:f800:0000:0000:0000:0000:0000"],
	    [38, nil, "ffff:ffff:fc00:0000:0000:0000:0000:0000"],
	    [39, nil, "ffff:ffff:fe00:0000:0000:0000:0000:0000"],
	    [40, nil, "ffff:ffff:ff00:0000:0000:0000:0000:0000"],
	    [41, nil, "ffff:ffff:ff80:0000:0000:0000:0000:0000"],
	    [42, nil, "ffff:ffff:ffc0:0000:0000:0000:0000:0000"],
	    [43, nil, "ffff:ffff:ffe0:0000:0000:0000:0000:0000"],
	    [44, nil, "ffff:ffff:fff0:0000:0000:0000:0000:0000"],
	    [45, nil, "ffff:ffff:fff8:0000:0000:0000:0000:0000"],
	    [46, nil, "ffff:ffff:fffc:0000:0000:0000:0000:0000"],
	    [47, nil, "ffff:ffff:fffe:0000:0000:0000:0000:0000"],
	    [48, nil, "ffff:ffff:ffff:0000:0000:0000:0000:0000"],
	    [49, nil, "ffff:ffff:ffff:8000:0000:0000:0000:0000"],
	    [50, nil, "ffff:ffff:ffff:c000:0000:0000:0000:0000"],
	    [51, nil, "ffff:ffff:ffff:e000:0000:0000:0000:0000"],
	    [52, nil, "ffff:ffff:ffff:f000:0000:0000:0000:0000"],
	    [53, nil, "ffff:ffff:ffff:f800:0000:0000:0000:0000"],
	    [54, nil, "ffff:ffff:ffff:fc00:0000:0000:0000:0000"],
	    [55, nil, "ffff:ffff:ffff:fe00:0000:0000:0000:0000"],
	    [56, nil, "ffff:ffff:ffff:ff00:0000:0000:0000:0000"],
	    [57, nil, "ffff:ffff:ffff:ff80:0000:0000:0000:0000"],
	    [58, nil, "ffff:ffff:ffff:ffc0:0000:0000:0000:0000"],
	    [59, nil, "ffff:ffff:ffff:ffe0:0000:0000:0000:0000"],
	    [60, nil, "ffff:ffff:ffff:fff0:0000:0000:0000:0000"],
	    [61, nil, "ffff:ffff:ffff:fff8:0000:0000:0000:0000"],
	    [62, nil, "ffff:ffff:ffff:fffc:0000:0000:0000:0000"],
	    [63, nil, "ffff:ffff:ffff:fffe:0000:0000:0000:0000"],
	    [64, nil, "ffff:ffff:ffff:ffff:0000:0000:0000:0000"],
	    [65, nil, "ffff:ffff:ffff:ffff:8000:0000:0000:0000"],
	    [66, nil, "ffff:ffff:ffff:ffff:c000:0000:0000:0000"],
	    [67, nil, "ffff:ffff:ffff:ffff:e000:0000:0000:0000"],
	    [68, nil, "ffff:ffff:ffff:ffff:f000:0000:0000:0000"],
	    [69, nil, "ffff:ffff:ffff:ffff:f800:0000:0000:0000"],
	    [70, nil, "ffff:ffff:ffff:ffff:fc00:0000:0000:0000"],
	    [71, nil, "ffff:ffff:ffff:ffff:fe00:0000:0000:0000"],
	    [72, nil, "ffff:ffff:ffff:ffff:ff00:0000:0000:0000"],
	    [73, nil, "ffff:ffff:ffff:ffff:ff80:0000:0000:0000"],
	    [74, nil, "ffff:ffff:ffff:ffff:ffc0:0000:0000:0000"],
	    [75, nil, "ffff:ffff:ffff:ffff:ffe0:0000:0000:0000"],
	    [76, nil, "ffff:ffff:ffff:ffff:fff0:0000:0000:0000"],
	    [77, nil, "ffff:ffff:ffff:ffff:fff8:0000:0000:0000"],
	    [78, nil, "ffff:ffff:ffff:ffff:fffc:0000:0000:0000"],
	    [79, nil, "ffff:ffff:ffff:ffff:fffe:0000:0000:0000"],
	    [80, nil, "ffff:ffff:ffff:ffff:ffff:0000:0000:0000"],
	    [81, nil, "ffff:ffff:ffff:ffff:ffff:8000:0000:0000"],
	    [82, nil, "ffff:ffff:ffff:ffff:ffff:c000:0000:0000"],
	    [83, nil, "ffff:ffff:ffff:ffff:ffff:e000:0000:0000"],
	    [84, nil, "ffff:ffff:ffff:ffff:ffff:f000:0000:0000"],
	    [85, nil, "ffff:ffff:ffff:ffff:ffff:f800:0000:0000"],
	    [86, nil, "ffff:ffff:ffff:ffff:ffff:fc00:0000:0000"],
	    [87, nil, "ffff:ffff:ffff:ffff:ffff:fe00:0000:0000"],
	    [88, nil, "ffff:ffff:ffff:ffff:ffff:ff00:0000:0000"],
	    [89, nil, "ffff:ffff:ffff:ffff:ffff:ff80:0000:0000"],
	    [90, nil, "ffff:ffff:ffff:ffff:ffff:ffc0:0000:0000"],
	    [91, nil, "ffff:ffff:ffff:ffff:ffff:ffe0:0000:0000"],
	    [92, nil, "ffff:ffff:ffff:ffff:ffff:fff0:0000:0000"],
	    [93, nil, "ffff:ffff:ffff:ffff:ffff:fff8:0000:0000"],
	    [94, nil, "ffff:ffff:ffff:ffff:ffff:fffc:0000:0000"],
	    [95, nil, "ffff:ffff:ffff:ffff:ffff:fffe:0000:0000"],
	    [96, nil, "ffff:ffff:ffff:ffff:ffff:ffff:0000:0000"],
	    [97, nil, "ffff:ffff:ffff:ffff:ffff:ffff:8000:0000"],
	    [98, nil, "ffff:ffff:ffff:ffff:ffff:ffff:c000:0000"],
	    [99, nil, "ffff:ffff:ffff:ffff:ffff:ffff:e000:0000"],
	    [100, nil, "ffff:ffff:ffff:ffff:ffff:ffff:f000:0000"],
	    [101, nil, "ffff:ffff:ffff:ffff:ffff:ffff:f800:0000"],
	    [102, nil, "ffff:ffff:ffff:ffff:ffff:ffff:fc00:0000"],
	    [103, nil, "ffff:ffff:ffff:ffff:ffff:ffff:fe00:0000"],
	    [104, nil, "ffff:ffff:ffff:ffff:ffff:ffff:ff00:0000"],
	    [105, nil, "ffff:ffff:ffff:ffff:ffff:ffff:ff80:0000"],
	    [106, nil, "ffff:ffff:ffff:ffff:ffff:ffff:ffc0:0000"],
	    [107, nil, "ffff:ffff:ffff:ffff:ffff:ffff:ffe0:0000"],
	    [108, nil, "ffff:ffff:ffff:ffff:ffff:ffff:fff0:0000"],
	    [109, nil, "ffff:ffff:ffff:ffff:ffff:ffff:fff8:0000"],
	    [110, nil, "ffff:ffff:ffff:ffff:ffff:ffff:fffc:0000"],
	    [111, nil, "ffff:ffff:ffff:ffff:ffff:ffff:fffe:0000"],
	    [112, nil, "ffff:ffff:ffff:ffff:ffff:ffff:ffff:0000"],
	    [113, nil, "ffff:ffff:ffff:ffff:ffff:ffff:ffff:8000"],
	    [114, nil, "ffff:ffff:ffff:ffff:ffff:ffff:ffff:c000"],
	    [115, nil, "ffff:ffff:ffff:ffff:ffff:ffff:ffff:e000"],
	    [116, nil, "ffff:ffff:ffff:ffff:ffff:ffff:ffff:f000"],
	    [117, nil, "ffff:ffff:ffff:ffff:ffff:ffff:ffff:f800"],
	    [118, nil, "ffff:ffff:ffff:ffff:ffff:ffff:ffff:fc00"],
	    [119, nil, "ffff:ffff:ffff:ffff:ffff:ffff:ffff:fe00"],
	    [120, nil, "ffff:ffff:ffff:ffff:ffff:ffff:ffff:ff00"],
	    [121, nil, "ffff:ffff:ffff:ffff:ffff:ffff:ffff:ff80"],
	    [122, nil, "ffff:ffff:ffff:ffff:ffff:ffff:ffff:ffc0"],
	    [123, nil, "ffff:ffff:ffff:ffff:ffff:ffff:ffff:ffe0"],
	    [124, nil, "ffff:ffff:ffff:ffff:ffff:ffff:ffff:fff0"],
	    [125, nil, "ffff:ffff:ffff:ffff:ffff:ffff:ffff:fff8"],
	    [126, nil, "ffff:ffff:ffff:ffff:ffff:ffff:ffff:fffc"],
	    [127, nil, "ffff:ffff:ffff:ffff:ffff:ffff:ffff:fffe"],
	    [128, nil, "ffff:ffff:ffff:ffff:ffff:ffff:ffff:ffff"],
	].each { |bits,ipv4,ipv6|

	    # bits is an integer: number of significant bits in netmask
	    # cidr is a string: netmask in CIDR format
	    cidr = "/#{bits}"
	    # ipv4 is a string: netmask in IPv4 dotted-quad format (or nil, for
	    # 	netmasks above /32)
	    # ipv6 is a string: netmask in IPv6 colon-hex format

	    # bitstr is bits (an integer) converted to a string
	    bitstr = bits.to_s

	    # Check that conversion to bits (integer) works for all inputs
	    assert_equal bits, Netomata::IPAddr.netmask_as_bits(bits)
	    assert_equal bits, Netomata::IPAddr.netmask_as_bits(bitstr)
	    assert_equal bits, Netomata::IPAddr.netmask_as_bits(cidr)
	    if ! ipv4.nil? then
		assert_equal bits, Netomata::IPAddr.netmask_as_bits(ipv4)
	    end
	    assert_equal bits, Netomata::IPAddr.netmask_as_bits(ipv6)

	    # Check that conversion to CIDR (string) works for all inputs
	    assert_equal cidr, Netomata::IPAddr.netmask_as_cidr(bits)
	    assert_equal cidr, Netomata::IPAddr.netmask_as_cidr(bitstr)
	    assert_equal cidr, Netomata::IPAddr.netmask_as_cidr(cidr)
	    if ! ipv4.nil? then
		assert_equal cidr, Netomata::IPAddr.netmask_as_cidr(ipv4)
	    end
	    assert_equal cidr, Netomata::IPAddr.netmask_as_cidr(ipv6)

	    # Check that conversion to dotted quads (string) works for all
	    if ! ipv4.nil? then
		assert_equal ipv4, Netomata::IPAddr.netmask_as_ipv4_quads(bits)
		assert_equal ipv4, Netomata::IPAddr.netmask_as_ipv4_quads(bitstr)
		assert_equal ipv4, Netomata::IPAddr.netmask_as_ipv4_quads(cidr)
		assert_equal ipv4, Netomata::IPAddr.netmask_as_ipv4_quads(ipv4)
		assert_equal ipv4, Netomata::IPAddr.netmask_as_ipv4_quads(ipv6)
	    end
	}
    end

    def test_netmask_examples

	assert_equal "255.255.255.0",
	    Netomata::IPAddr.new("198.102.244.34/24").netmask
	assert_equal "ffff:ffff:ffff:ffff:ffff:0000:0000:0000",
	    Netomata::IPAddr.new("dead:beef:0123:4567::cafe:babe/80").netmask

	assert_equal 30,
	    Netomata::IPAddr.new("172.16.32.16/255.255.255.252").netmask_as_bits
	assert_equal 24,
	    Netomata::IPAddr.new("198.102.244.34/24").netmask_as_bits

	assert_equal 30, Netomata::IPAddr.netmask_as_bits("255.255.255.252")
	assert_equal 32, Netomata::IPAddr.netmask_as_bits("ffff:ffff::")
	assert_equal 24, Netomata::IPAddr.netmask_as_bits("/24")
	assert_equal 18, Netomata::IPAddr.netmask_as_bits("18")
	assert_equal 12, Netomata::IPAddr.netmask_as_bits(12)

	assert_equal "/30",
	    Netomata::IPAddr.new("10.5.16.0/255.255.255.252").netmask_as_cidr
	assert_equal "/24",
	    Netomata::IPAddr.new("198.102.244.34/24").netmask_as_cidr
	assert_equal "/32",
	    Netomata::IPAddr.new("cafe:babe:1234::/ffff:ffff::").netmask_as_cidr

	assert_equal "/30", Netomata::IPAddr.netmask_as_cidr("255.255.255.252")
	assert_equal "/48", Netomata::IPAddr.netmask_as_cidr("ffff:ffff:ffff::")
	assert_equal "/24", Netomata::IPAddr.netmask_as_cidr("/24")
	assert_equal "/18", Netomata::IPAddr.netmask_as_cidr(18)

	assert_equal "255.255.255.252",
	    Netomata::IPAddr.new("10.5.16.0/255.255.255.252").netmask_as_ipv4_quads
	assert_equal "255.255.255.0",
	    Netomata::IPAddr.new("198.102.244.34/24").netmask_as_ipv4_quads
	assert_equal nil,
	    Netomata::IPAddr.new("cafe:babe:1234::/ffff:ffff::").netmask_as_ipv4_quads

	assert_equal "255.255.255.252",
	    Netomata::IPAddr.netmask_as_ipv4_quads(30)
	assert_equal "255.255.255.240",
	    Netomata::IPAddr.netmask_as_ipv4_quads("/28")
    end
end
