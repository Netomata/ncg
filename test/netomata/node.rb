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
	# assert_raise ArgumentError do
	#     @node["!(k_common_kv=v_common_kv)!k_n1a1"]
	# end
    end

    def test_append
	@node["!n1!(+)"] = "v_n1a4"
	assert_equal "v_n1a4", @node["!n1!(>)"]
    end

end
