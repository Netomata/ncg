# $Id$
# Copyright (C) 2008, 2009 Netomata, Inc.  All Rights Reserved. 
# Please review accompanying 'LICENSE' file or
# http://www.netomata.com/docs/licenses/ncg for important notices,
# disclaimers, and license terms.

cwd = Dir.getwd
ENV["NETOMATA_LIB"] = File.expand_path(File.join(File.dirname(__FILE__),"lib"))

require 'rake/testtask'

$svn_base_url="https://dev.netomata.com/svn/ncg"
$svn_trunk_url="#{$svn_base_url}/trunk"

def determine_svn_branch
    # URL: https://dev.netomata.com/svn/ncg/trunk	 => ""
    # URL: https://dev.netomata.com/svn/ncg/branch/brent => branch/brent
    branch = IO.popen("svn info").grep(/^URL:/)[0].chomp!
    branch.sub!("URL: #{$svn_base_url}/", "")
    if (branch.eql?("trunk")) then
	return ""
    else
	return branch
    end
end

def determine_svn_revision(rev=nil)
    if rev.nil? then
	cmd = "svn info"
    else
	cmd = "svn info -r #{rev}"
    end

    IO.popen(cmd).grep(/^Revision: /)[0].chomp!.split[1]
end

$svn_revision=determine_svn_revision()
$svn_branch=determine_svn_branch()
$svn_working_branch="branches/brent"

desc "Run all tests and generate/compare sample configs against baselines"
task "default" => ["test", "sample"]

lib_dir = File.expand_path('netomata')

desc "Run all tests"
task "test" => ["lib/netomata/version.rb", "do_test"]

Rake::TestTask.new("do_test") do |t|
    t.pattern = 'test/**/*.rb'
    t.libs = [lib_dir]
#   t.warning = true
end

desc "Generate sample configs and diff against baseline"
task "sample" => ["sample/switches"]

desc "Generate sample/switches configs and diff against baseline"
task "sample" => ["lib/netomata/version.rb"] do
    sh 'rm -f sample/switches/configs/switch-1.config sample/switches/configs/switch-2.config'
    sh 'bin/ncg -v sample/switches/switches.neto'
    sh 'egrep -v "^!!" sample/switches/configs/switch-1.config | diff -u sample/switches/configs/switch-1.baseline -'
    sh 'egrep -v "^!!" sample/switches/configs/switch-2.config | diff -u sample/switches/configs/switch-2.baseline -'
    puts "############"
    puts "# Success! #"
    puts "############"
end

desc "Generate docs from Netomata web site"
task "doc" => ["lib/netomata/version.rb"] do
    sh 'dev/get_docs.rb'
end

desc "Generate RDOC documentation"
task "rdoc" do
    sh 'rm -rf rdoc'
    sh 'rdoc -o rdoc -a lib/netomata.rb lib/netomata/'
end

desc "Check whether 'svn commit' or 'svn update' is needed"
task "check_commit_update" do
    puts "checking whether 'svn commit' or 'svn update' is needed..."
    unless IO.popen("svn status").readlines.length == 0
	fail ("#"*60 + "\n" +
	      "'svn status' is not clean; are there unchecked-in files?\n" +
	      "Need to do:\n\tsvn commit\n" +
	      "#"*60)
    end
    svn_info_rev = determine_svn_revision()
    svn_info_head_rev = determine_svn_revision("HEAD")
    unless (svn_info_rev == svn_info_head_rev)
	fail ("#"*60 + "\n" + 
	      "Version mismatch:\n" +
	      "\tsvn info\t\t=> #{svn_info_rev}\n" +
	      "\tsvn info -r HEAD\t=> #{svn_info_head_rev}\n" +
	      "Need to do:\n\tsvn update\n" +
	      "#"*60)
    end
end

desc "Snapshot current SVN trunk to demo tag"
task "tag_demo" => ["test", "sample", "check_commit_update"] do
    sh "svn delete $svn_base_url/tags/demo -m 'Removing old demo tag'"
    sh "svn copy $svn_base_url/trunk $svn_base_url/tags/demo -m 'Setting new demo tag'"
end

desc "Accept the current generated sample configs as the new baseline"
task "sample_accept" => ["sample/configs/switch-1.config",
			    "sample/configs/switch-2.config"] do
    sh "cp -p sample/configs/switch-1.config sample/configs/switch-1.baseline"
    sh "sed -e '/^!!/d' -i '' sample/configs/switch-1.baseline"
    sh "cp -p sample/configs/switch-2.config sample/configs/switch-2.baseline"
    sh "sed -e '/^!!/d' -i '' sample/configs/switch-2.baseline"
end

dist_ignore = File.new("dev/ignore.dist").readlines
dist_ignore.each { |l|
    # remove trailing newline
    l.chomp!
    # remove comments
    l.sub(/#.*/, "")
}
# remove blank lines (possibly remains of comments)
dist_ignore.reject! { |l| l == "" }
# divide into list of directories (i.e., entries ending with "/") and files
dist_ignore_dirs, dist_ignore_files = dist_ignore.partition {|e| e[-1,1] == "/"}

dist_files = FileList['**/*']
dist_files.exclude { |f| 
    if File.directory?(f) then
	# exclude all directories (though not necessarily their contents)
	true
    elsif dist_ignore_files.include?(f)
	# exclude all files specificly named in "ignore.dist"
	true
    else
	# exclude contents of all directories named in "ignore.dist"
	dist_ignore_dirs.collect { |i| f[0,i.length] == i }.any?
    end
}

desc "Create a 'VERSION' file for distribution"
#task "VERSION" => ["check_commit_update"] do
task "VERSION" do
    puts "generating VERSION..."
    release = File.new("dev/RELEASE").readline.chomp!
    v = File.new("VERSION", "w")
    v.truncate(0)
    if ($svn_branch.eql?("")) then
	v.puts("#{release}-r#{$svn_revision}")
    else
	v.puts("#{release}-r#{$svn_revision}-#{$svn_branch.sub(/^.*\//,"")}")
    end
    v.close
end

desc "Create a 'lib/netomata/version.rb' file for distribution"
file "lib/netomata/version.rb" => ["VERSION"] do
    version = File.new("VERSION").readline.chomp!
    vf = File.new("lib/netomata/version.rb", "w")
    vf.print <<"EOF"
# Do not edit -- generated by Rakefile
class Netomata
        Version = "#{version}"
end
EOF
    vf.close
end

desc "Create all files for distribution"
task "dist" => ["dist_dir", "check_commit_update", "VERSION", "lib/netomata/version.rb", "Manifest", "Versions", "dist_tar", "dist_tar_gz"]

desc "Clean out the dist directory"
task "dist_clean" do
    sh "rm -rf dist/*"
end

desc "Create 'dist' directory"
task "dist_dir" do
    if ! (File.exists?("dist") && File.directory?("dist")) then
	Dir.mkdir("dist")
    end
end 

desc "Create a 'tar' file for distribution"
task "dist_tar" => ["dist_dir", "VERSION", "Manifest"] do
    version = File.new("VERSION").readline.chomp!
    base = "ncg-#{version}"
    distbase = "dist/#{base}"
    sh "rm -f #{distbase}"
    sh "ln -s .. #{distbase}"
    sh "sed -e 's,^,#{base}/,' Manifest | tar chCfT dist #{distbase}.tar -"
end

desc "Create a 'tar.gz' file for distribution"
task "dist_tar_gz" => ["dist_dir", "dist_tar"] do
    version = File.new("VERSION").readline.chomp!
    base = "ncg-#{version}"
    distbase = "dist/#{base}"
    sh "gzip -c #{distbase}.tar > #{distbase}.tar.gz"
end

desc "Create Manifest"
task "Manifest" => ["doc"]  do
    puts "generating Manifest..."
    m = File.new("Manifest", "w")
    m.truncate(0)
    dist_files.sort.each { |l|
	m.puts(l)
    }
    m.close
end

desc "Create Versions"
task "Versions" do
    puts "generating Versions..."
    sh 'svn info > Versions'
    sh 'svn status -v >> Versions'
end

desc "Update svn:ignore property"
task "svn_ignore" do
    FileList["**/.svn.ignore"].each {|f|
	Dir.chdir(File.dirname(f)) { |d|
	    puts "(in #{d})"
	    sh 'svn ps svn:ignore -F .svn.ignore .'
	}
    }
end

desc "Verify we're working in a branch"
task "verify_in_branch" do
    if $svn_branch.eql?("") then
	fail("#"*60 + "\n" +
	      "Must be working in a branch!\n" +
	      "#"*60)
    end
end

desc "Verify we're working in trunk"
task "verify_in_trunk" do
    if ! $svn_branch.eql?("") then
	fail("#"*60 + "\n" +
	      "Must be working in trunk!\n" +
	      "Currently working in: #{$svn_branch}\n" +
	      "#"*60)
    end
end

desc "Merge changes from trunk into current branch"
task "merge_from_trunk" => ["verify_in_branch"] do
    sh "svn merge #{$svn_trunk_url}"
    sh "svn update"
    sh "svn status"
end

desc "Merge changes from current branch into trunk"
task "merge_to_trunk" => ["check_commit_update", "verify_in_branch"] do
    sh "svn switch #{$svn_trunk_url}"
    sh "svn update"
    sh "svn merge --reintegrate #{$svn_base_url}/#{$svn_branch}"
    sh "svn update"
    sh "svn log --stop-on-copy #{$svn_base_url}/#{$svn_branch} | egrep -v '^--*$|^r[0-9][0-9]* \\|' > /tmp/svn_merge_log"
    puts "#"*60
    puts "####"
    puts "#### REMINDER: now working in trunk!"
    puts "####"
    puts "#"*60
    puts ""
    puts "Examine changes and revise log entry in /tmp/svn_merge_log"
    puts "\tvi /tmp/svn_merge_log"
    puts "When ready to accept, do"
    puts "\tsvn commit -F /tmp/svn_merge_log"
    puts "\tsvn update"
    puts "\trake delete_branch"
    puts ""
    puts "#"*60
end

desc "Delete working branch"
task "delete_branch" do
    if (`svn list #{$svn_base_url}/#{File.dirname($svn_working_branch)} | grep #{File.basename($svn_working_branch)}` == "") then
	print "#{$svn_base_url}/#{$svn_working_branch} doesn't exist\n"
    else
	sh "svn delete #{$svn_base_url}/#{$svn_working_branch} -m 'Delete working branch'"
    end
end

desc "Make working branch from trunk"
task "make_branch" do
    sh "svn copy #{$svn_trunk_url} #{$svn_base_url}/#{$svn_working_branch} -m 'Create working branch from trunk'"
end

desc "Switch from trunk to branch"
task "switch_to_branch" do
    sh "svn switch #{$svn_base_url}/#{$svn_working_branch}"
end

desc "Delete old working branch, create new branch from trunk, and switch to branch"
task "new_branch" => ["verify_in_trunk", "check_commit_update", "delete_branch", "make_branch", "switch_to_branch"] do
    puts "#"*60
    puts "####"
    puts "#### Now working in #{$svn_working_branch}!"
    puts "####"
    puts "#"*60
end

desc "Diff working branch against trunk"
task "diff_branch" do
    sh "svn diff #{$svn_trunk_url} #{$svn_base_url}/#{$svn_working_branch}"
end
