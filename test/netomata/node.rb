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

class NodeTest < Test::Unit::TestCase
    def setup
	@node = Netomata::Node.new
	@node["!n1"] = Netomata::Node.new
	@node["!n1!k_n1a1"] = "v_n1a1"
	@node["!n1!k_n1a2"] = "v_n1a2"
	@node["!n1!k_n1a3"] = "v_n1a3"
	@node["!n2!k_n2a1"] = "v_n2a1"
	@node["!n2!k_n2a2"] = "v_n2a2"
	@node["!n2!k_n2a3"] = "v_n2a3"
    end

    def test_n1a1_get
	assert_equal "v_n1a1", @node["!n1!k_n1a1"]
    end

    def test_n1a1_set
	old = @node["!n1!k_n1a1"]
	@node["!n1!k_n1a1"] = "new_v_n1a1"
	assert_equal "new_v_n1a1", @node["!n1!k_n1a1"]
	# restore old value
	@node["!n1!k_n1a1"] = old
    end

    def test_n1a4_set
	assert_equal nil, @node["!n1!k_n1a4"]
	@node["!n1!k_n1a4"] = "new_v_n1a4"
	assert_equal "new_v_n1a4", @node["!n1!k_n1a4"]
    end

    def test_append
	mk = @node["!n1"].keys.max
	nk = mk.succ
	nv = nk.gsub(/^k_/, "new_v_")
	@node["!n1!(+)"] = nv
	assert_equal nv, @node["!n1!" + nk]
    end
end
