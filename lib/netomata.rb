# $Id$
# Copyright (c) 2008 Netomata, Inc.  All Rights Reserved. 
# Please review accompanying 'LICENSE' file or
# http://www.netomata.com/license_v1 for important notices,
# disclaimers, and license terms (GPL v2.0 or alternative).

require 'rubygems'
require 'erb'
require 'facets'
require 'facets/dictionary'
require 'ipaddr'
begin	# rescue block; no big deal if these aren't found, since
    	# they're only used for debugging
    require 'pp'
    require 'breakpoint'
    require 'ruby-debug'
rescue LoadError
    # 
end

class Netomata
    # stub class, for other files to add subclasses to
end

require 'netomata/version'
require 'netomata/utilities'
require 'netomata/node'
require 'netomata/template'
