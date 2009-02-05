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
lib = File.expand_path(File.join(File.dirname(__FILE__), '..', 'lib'))
if not $LOAD_PATH.include?(lib) then $LOAD_PATH.unshift(lib) end
$testfiles = File.join(cwd,"files")


require 'netomata'

require 'test/unit'
require 'tempfile'
require 'stringio'
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
    public :simple_key?
    public :valid?
end

class NodeTest_1_Fundamentals < Test::Unit::TestCase
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
	assert_equal nil, @n.node_fetch("n1!n11!n114!k1141")	# missing node
    end

    def test_simple_key
	assert_equal true, @n.simple_key?("a")
	assert_equal false, @n.simple_key?("!")
	assert_equal false, @n.simple_key?("!a")
	assert_equal false, @n.simple_key?("a!")
	assert_equal false, @n.simple_key?("a!b")
	assert_equal false, @n.simple_key?("(x)")
	assert_equal false, @n.simple_key?("{y}")
	assert_equal false, @n.simple_key?(nil)
	assert_equal false, @n.simple_key?(123)
    end
end

class NodeTest_2_General < Test::Unit::TestCase
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

    def test_selector_dot
	assert_same @node["!n1!n11"], @node["!n1!n11!(.)"]
	assert_same @node["!n1!n11"], @node["!n1!(.)!n11"]
	assert_same @node["!n1!n11"], @node["!(.)!n1!n11"]
	assert_same @node["!n1!n11"], @node["!(.)!n1!(.)!n11"]
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
	assert @node.valid?
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
	assert @node.has_key?("!n1")
	assert @node.has_key?("n1")
	assert @node.has_key?("!n1!n11")
	assert @node.has_key?("n1!n11")
	assert_equal false, @node.has_key?("!n4")
	assert_equal false, @node.has_key?("n4")
	assert_equal false, @node.has_key?("!n1!n14")
	assert_equal false, @node.has_key?("n1!n14")
    end

    def test_keys_having_key
	assert_equal [], @node.keys_having_key("k_uncommon_k")
	assert_equal ["!n1", "!n2"], @node.keys_having_key("k_common_k")
    end

    def test_equivalent
	assert_equal true, @node.equivalent(@node)
	assert_equal true, @node["n1"].equivalent(@node["n1"])
	assert_equal false, @node.equivalent(@node["n1"])
	assert_equal true, @node["!n1!k_common_n"].
	    			equivalent(@node["!n2!k_common_n"])
    end
end

class NodeTest_3_Import_Table < Test::Unit::TestCase
    def setup
	@n = Netomata::Node.new(nil)
	@n["!devices!(+)!hostname"] = "switch-1"
	@n["!devices!(+)!hostname"] = "switch-2"
	@n.import_table(File.join($testfiles,
				  "node_test_import_table.neto_table"
				 )
		       )
    end

    def test_import_table
	assert @n.valid?
	output = PP::pp(@n, StringIO.new)
	expected = File.new(File.join($testfiles, 
				      "node_test_import_table.pp"
				     )
			   ).readlines.join
	assert_equal expected, output.string
    end

    def test_dump_imported_table
	# To re-create tests data file, uncomment following line:
	# @n.dump(File.new("/tmp/node_dump_imported_table.neto", "w"),0,false)
	
	# dump to a file
	t = Tempfile.new("ncg_test.dump_imported_table.neto", "/tmp")
	@n.dump(t,0,false)
	t.close

	# check that the dumped file matches what it should
	assert FileUtils.compare_file(t.path,
				      File.join($testfiles,
						"node_dump_imported_table.neto")
				     )

	# import the file that was just created with dump
	n2 = Netomata::Node.new(nil)
	n2.import_file(t.path)

	# check that the data structure you get from re-importing is the same
	# as the original data structure
	assert_equal @n, n2
    end
end

class NodeTest_4_Import_File < Test::Unit::TestCase
    def setup

	@tmpdirname = "/tmp/ncg_test.#{self.class}.#{$$}"

	def setup_dir(bottom,*parts)
	    Dir.mkdir(File.join(@tmpdirname,parts))
	    f = File.new(File.join(@tmpdirname, parts,"file.neto"),"w")
	    if (parts.length > 0) then
		f.print("loc = ", File.join(parts), "\n")
	    else
		f.print("loc = top\n")
	    end
	    f.print <<EOF
filename = <%= @target["{FILENAME}"] %>
basename = <%= @target["{BASENAME}"] %>
dirname = <%= @target["{DIRNAME}"] %>
EOF

	    if (! bottom) then
		f.printf <<EOF
a {
    include a/file.neto
}
b {
    include b/file.neto
}
c {
    include c/file.neto
}
d {
    include d/file.neto
}
EOF
	    end
	    f.close
	end

	setup_dir(false)
	for i1 in 'a' .. 'd' do
	    setup_dir(false,i1)
	    for i2 in 'a' .. 'd' do
		setup_dir(false,i1,i2)
		for i3 in 'a' .. 'd' do
		    setup_dir(true,i1,i2,i3)
		end
	    end
	end
    end

    def teardown
	FileUtils.rm_rf(@tmpdirname)
    end

    def test_import_file
	# also tests metadata_fetch, since each .neto file in generated test
	# 	tree includes references to @target["{FILENAME}"],
	# 	@target["{BASENAME}"], and @target["{DIRNAME}"]
	# also tests nested includes with relative keys and relative filenames,
	#	since the .neto files in the generated test tree are set up
	#	that way
	# also tests dump and re-import of file (done here instead of in
	# 	a dedicated test_ method so that setup/teardown doesn't need
	# 	to be repeated)
	n = Netomata::Node.new(nil)
	Dir.chdir(@tmpdirname) do
	    n.import_file("file.neto")
	end
	assert n.valid?
	output = PP::pp(n, StringIO.new)
	# To re-create test data file, uncomment following line:
	# File.new("/tmp/node_test_import_file.pp", "w").print(output.string)
	expected = File.new(File.join($testfiles, "node_test_import_file.pp")).readlines.join
	assert_equal expected, output.string

	# To re-create test data file, uncomment following line:
	# n.dump(File.new("/tmp/node_dump_imported_file.neto", "w"),0,false)
	
	# dump to a file
	t = Tempfile.new("ncg_test.dump_imported_file.neto", "/tmp")
	n.dump(t,0,false)
	t.close

	# check that the dumped file matches what it should
	assert FileUtils.compare_file(t.path,
				      File.join($testfiles,
						"node_dump_imported_file.neto")
				     )

	# import the file that was just created with dump
	n2 = Netomata::Node.new(nil)
	n2.import_file(t.path)

	# check that the data structure you get from re-importing is the same
	# as the original data structure
	assert_equal n, n2
    end
end

class NodeTest_5_Exception_Backtrace < Test::Unit::TestCase
    def test_exception_backtrace
	bt = []
	begin	# rescue block
	    n = Netomata::Node.new(nil)
	    Dir.chdir(File.join($testfiles, "node_exception_backtrace")) do
		n.import_file("file.neto")
	    end
	rescue => exc
	    bt = exc.backtrace
	    # no raise
	end
	assert_equal(
	"./a/b/c/file.neto:5\n./a/b/file.neto:12\n./a/file.neto:9\nfile.neto:6",
		bt[0..3].join("\n"))
    end
end

class NodeTest_6_Import_Template < Test::Unit::TestCase
    def setup

	@tmpdirname = "/tmp/ncg_test.#{self.class}.#{$$}"

	def setup_template(filename)
	    f = File.new(File.join(@tmpdirname,filename),"w")
	    f.print("this = ", filename, "\n")
	    f.close
	    @templates_all.print "!templates!",
		filename.sub(/\.ncg$/,'').gsub(File::Separator,'!')
	    @templates_all.print <<EOF
 {
    template #{filename}
}
EOF
	end

	def setup_dir(bottom,*parts)
	    Dir.mkdir(File.join(@tmpdirname,parts))
	    f = File.new(File.join(@tmpdirname, parts,"templates.neto"),"w")
	    if (parts.length == 0) then
		# this is the top-level directory
		@templates_all = File.open(File.join(@tmpdirname,
						    "templates_all.neto"),"w")
	    end
	    for i in 'a'..'d' do
		f.printf "#{i} {\n"
		f.printf "    template #{i}.ncg\n"
		if (parts.length == 0) then
		    setup_template("#{i}.ncg")
		else
		    setup_template(File.join(parts,"#{i}.ncg"))
		end
		if (! bottom) then
		    f.printf "    include #{i}/templates.neto\n"
		end
		f.printf "}\n"
	    end
	    f.close
	end

	setup_dir(false)
	for i1 in 'a' .. 'd' do
	    setup_dir(false,i1)
	    for i2 in 'a' .. 'd' do
		setup_dir(false,i1,i2)
		for i3 in 'a' .. 'd' do
		    setup_dir(true,i1,i2,i3)
		end
	    end
	end

	@templates_all.close

	tf = File.new(File.join(@tmpdirname,"template_dir.neto"),"w")
	tf.print <<EOF
!templates {
    template_dir .
}
EOF
	tf.close

	tf = File.new(File.join(@tmpdirname,"template_dir_deep.neto"),"w")
	tf.print <<EOF
!templates-aa {
    template_dir a/a
}
!templates-ab {
    template_dir a/b
}
!templates-bb {
    template_dir b/b
}
!templates-ba {
    template_dir b/a
}
!templates-cba {
    template_dir c/b/a
}
!templates-abc {
    template_dir a/b/c
}
EOF
	tf.close

	tf = File.new(File.join(@tmpdirname,"templates_top.neto"),"w")
	tf.print <<EOF
!templates {
    include templates.neto
}
EOF
	tf.close

    end

    def teardown
	FileUtils.rm_rf(@tmpdirname)
    end

    def test_import_template
	# Multiple tests are done here instead of in separate test_ methods,
	# so that setup/teardown (which is slow, because it creates/deletes
	# a large number of directories and files) doesn't need to be repeated.
	
	# check_template(template_filename) -> node
	# 1) Creates a node, and loads it from the named template_filename
	# 2) Checks it against the corresponding reference dump
	# 3) returns the node
	def check_template(template_filename)
	    template_basename = File.basename(template_filename,".neto")
	    n = Netomata::Node.new(nil)
	    n.import_file(template_filename)
	    # To re-create test data file, uncomment following line:
	    # 	n.dump(File.new("/tmp/#{template_basename}.dump", "w"),0,false)
	    # Examine the file, then do
	    #   mv /tmp/#{template_basename}.dump
	    #      test/netomata/files/node_test_import_#{tempate_basename}.dump
	    n_expected =
		File.new(
		    File.join($testfiles,
			      "node_test_import_#{template_basename}.dump")
	        ).readlines.join
	    n_output = StringIO.new
	    n.dump(n_output,0,false)
	    assert_equal n_expected, n_output.string
	    return n
	end

	Dir.chdir(@tmpdirname) do
	    n_templates_all = check_template("templates_all.neto")

	    n_templates_top = check_template("templates_top.neto")
	    assert n_templates_top.equivalent(n_templates_all)

	    n_template_dir = check_template("template_dir.neto")
	    assert n_template_dir.equivalent(n_templates_all)

	    n_template_dir_deep = check_template("template_dir_deep.neto")
	end
    end
end
