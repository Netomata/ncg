# $Id$
# Copyright (C) 2008, 2009 Netomata, Inc.  All Rights Reserved. 
# Please review accompanying 'LICENSE' file or
# http://www.netomata.com/docs/licenses/ncg for important notices,
# disclaimers, and license terms.

# Extends the Ruby base IPAddr class, primarily to add functions for
# returning netmasks in various formats

require 'ipaddr'

class Netomata::IPAddr < IPAddr

    @@ipv4_netmask_table = (0..32).collect { |b|
	r = 32 - b
	((IN4MASK >> r) << r)
    }.freeze

    @@ipv6_netmask_table = (0..128).collect { |b|
	r = 128 - b
	((IN6MASK >> r) << r)
    }.freeze

    # :call-seq:
    # ipaddr.netmask -> string
    #
    # Returns _ipaddr_'s netmask as a string in canonical format
    # (dotted-quad for IPv4, and ':'-separated hex for IPv6)
    #
    # For example:
    # * Netomata::IPAddr.new("198.102.244.34/24").netmask -> "255.255.255.0"
    # * Netomata::IPAddr.new("dead:beef:0123:4567::cafe:babe/80").netmask ->
    #   "ffff:ffff:ffff:ffff:ffff:0000:0000:0000"
    def netmask
	return _to_string(@mask_addr)
    end

    # :call-seq:
    # ipaddr.netmask_as_bits -> int
    #
    # Returns the number of significant bits in the netmask of _ipaddr_.
    #
    # For example:
    # * Netomata::IPAddr.new("172.16.32.16/255.255.255.252").netmask_as_bits 
    #   -> 30
    # * Netomata::IPAddr.new("198.102.244.34/24").netmask_as_bits -> 24

    def netmask_as_bits
	case @family
	when Socket::AF_INET
	    return @@ipv4_netmask_table.index(@mask_addr)
	when Socket::AF_INET6
	    return @@ipv6_netmask_table.index(@mask_addr)
	else
	    raise ArgumentError, "unsupported address family"
	end
    end

    # :call-seq:
    # Netomata::IPAddr.netmask_as_bits(netmask) -> int
    #
    # Returns the number of significant bits in _netmask_, which is
    # expressed in any of the following forms:
    #
    # * string in IPv4 dotted-quad notation (i.e., "255.255.252.0")
    # * string in IPv6 colon-separated-hex notation (i.e., "ffff:ffff::")
    # * string in IPv4 or IPv6 CIDR notation (i.e., "/24" or "/40") 
    # * string as number of bits (i.e., "30")
    # * integer as number of bits (i.e., 27)
    #
    # For example:
    #
    # * Netomata::IPAddr.netmask_as_bits("255.255.255.252") -> 30
    # * Netomata::IPAddr.netmask_as_bits("ffff:ffff::") -> 32
    # * Netomata::IPAddr.netmask_as_bits("/24") -> 24
    # * Netomata::IPAddr.netmask_as_bits("18") -> 18
    # * Netomata::IPAddr.netmask_as_bits(12) -> 12

    def self.netmask_as_bits(mask)
	if mask.kind_of?(String) then
	    if (/^(\d{1,3})\.(\d{1,3})\.(\d{1,3})\.(\d{1,3})$/ =~ mask) then
		# looks like an IPv4 netmask; check that all parts are valid
		unless ($~.captures.all? { |p| p.to_i < 256 }) 
		    raise ArgumentError, "Invalid netmask '#{mask}'"
		end
		return Netomata::IPAddr.new("0.0.0.0/" + mask).netmask_as_bits
	    elsif (/^[\dA-Za-z:]*$/ =~ mask) then
		# looks like maybe an IPv6 netmask; see if it's valid
		return Netomata::IPAddr.new("::/" + mask).netmask_as_bits
	    elsif (/^\/(\d+)$/ =~ mask) || (/^(\d+)$/ =~ mask) then
		# looks like maybe "/bits" or "bits"
		b = $1.to_i
		if ((b >= 0) && (b <= 128)) then
		    return b
		else
		    raise ArgumentError, "Invalid netmask '#{mask}'"
		end
	    end
	elsif mask.kind_of?(Integer) then
	    if ((mask >= 0) && (mask <= 128)) then
		return mask
	    else
		raise ArgumentError, "Invalid netmask '#{mask}'"
	    end
	end
	raise ArgumentError, "Invalid netmask '#{mask}'"
    end

    # :call-seq:
    # ipaddr.netmask_as_cidr -> string
    #
    # Returns the netmask of _ipaddr_ as a string in CIDR notation
    #
    # For example:
    #
    # * Netomata::IPAddr.new("10.5.16.0/255.255.255.252").netmask_as_cidr 
    #   -> "/30"
    # * Netomata::IPAddr.new("198.102.244.34/24").netmask_as_cidr -> "/24"
    # * Netomata::IPAddr.new("cafe:babe:1234::/ffff:ffff::").netmask_as_cidr 
    #   -> "/32"
    def netmask_as_cidr
	b = self.netmask_as_bits
	if (b.nil?) then
	    return nil
	else
	    "/" + b.to_s
	end
    end

    # :call-seq:
    # Netomata::IPAddr.netmask_as_cidr(netmask) -> string
    #
    # Returns a netmask as a string in CIDR notation, from input
    # _netmask_ expressed in any of the following forms:
    #
    # * string in IPv4 dotted-quad notation (i.e., "255.255.252.0")
    # * string in IPv6 colon-separated-hex notation (i.e., "ffff:ffff::")
    # * string in IPv4 or IPv6 CIDR notation (i.e., "/24" or "/40") 
    # * string as number of bits (i.e., "30")
    # * integer as number of bits (i.e., 27)
    #
    # For example:
    #
    # * Netomata::IPAddr.netmask_as_cidr("255.255.255.252") -> "/30"
    # * Netomata::IPAddr.netmask_as_cidr("ffff:ffff:ffff::") -> "/48"
    # * Netomata::IPAddr.netmask_as_cidr("/24") -> "/24"
    # * Netomata::IPAddr.netmask_as_cidr(18) -> "/18"

    def self.netmask_as_cidr(bits)
	# call netmask_as_bits to validate and convert to int
	ibits = Netomata::IPAddr.netmask_as_bits(bits)
	if (ibits.nil?) then
	    return nil
	else
	    return "/#{ibits}"
	end
    end

    # :call-seq:
    # ipaddr.netmask_as_ipv4_quads -> string
    #
    # If _ipaddr_ is an IPv4 address, returns a string which is
    # _ipaddr_'s netmask in dotted_quad (IPv4) notation. 
    # Otherwise, returns nil.
    #
    # For example:
    #
    # * Netomata::IPAddr.new("10.5.16.0/255.255.255.252").netmask_as_ipv4_quads
    #   -> "255.255.255.252"
    # * Netomata::IPAddr.new("198.102.244.34/24").netmask_as_ipv4_quads
    #   -> "255.255.255.0"
    # * Netomata::IPAddr.new("cafe:babe::/ffff:ffff::").netmask_as_ipv4_quads
    #   -> nil
    
    def netmask_as_ipv4_quads
	return nil unless self.ipv4?
	return self.netmask	# canonical format for IPv4 _is_ dotted quad
    end

    # :call-seq:
    # Netomata::IPAddr.netmask_as_ipv4_quads(netmask) -> string
    #
    # Returns a string which is _netmask_ represented in dotted-quad (IPv4)
    # notation.  _netmask_ may be given in any of the following forms:
    #
    # * string in IPv4 dotted-quad notation (i.e., "255.255.252.0")
    # * string in IPv4 or IPv6 CIDR notation (i.e., "/24" or "/40") 
    # * string as number of bits (i.e., "30")
    # * integer as number of bits (i.e., 27)
    #
    # _netmask_ must be an IPv4 netmask (i.e., 0 to 32 bits). 
    # If _netmask_ is not a valid IPv4 netmask, then an error is raised.
    #
    # For example:
    #
    # * Netomata::IPAddr.netmask_as_ipv4_quads(30) -> "255.255.255.252"
    # * Netomata::IPAddr.netmask_as_ipv4_quads("/28") -> "255.255.255.240"

    def self.netmask_as_ipv4_quads(bits)
	# call netmask_as_bits to validate and convert to int
	ibits = Netomata::IPAddr.netmask_as_bits(bits)
	# netmask_as_bits could return 0..128, but only 0..32 is valid
	# for IPv4.  So, check that answer is in range before proceeding.
	if (ibits > 32) then
	    raise RangeError, "#{bits} out of range 0..32 for IPv4 netmask"
	end
	return Netomata::IPAddr.new("0.0.0.0/#{ibits}").netmask
    end

end
