# $Id$
# Copyright (C) 2008, 2009 Netomata, Inc.  All Rights Reserved. 
# Please review accompanying 'LICENSE' file or
# http://www.netomata.com/docs/licenses/ncg for important notices,
# disclaimers, and license terms.

require 'rubygems'
require 'erb'
require 'etc'
require 'facets/dictionary'
require 'ipaddr'
require 'pp'
require 'socket'
require 'fileutils'
begin	# rescue block; no big deal if these aren't found, since
    	# they're only used for debugging
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
require 'netomata/fileset'
require 'netomata/ipaddr'
require 'netomata/node'
require 'netomata/template'
