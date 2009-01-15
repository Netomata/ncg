# $Id$
# Copyright (c) 2008 Netomata, Inc.  All Rights Reserved. 
# Please review accompanying 'LICENSE' file or
# http://www.netomata.com/license_v1 for important notices,
# disclaimers, and license terms (GPL v2.0 or alternative).

cwd = Dir.getwd
ENV["NETOMATA_LIB"] = File.expand_path(File.join(File.dirname(__FILE__),"lib"))

require 'rake/testtask'

def svn_revision(rev=nil)
    if rev.nil? then
	cmd = "svn info"
    else
	cmd = "svn info -r #{rev}"
    end

    IO.popen(cmd).grep(/^Revision: /)[0].chomp!.split[1]
end

desc "Run all tests and generate/compare configs against baselines"
task "default" => ["test", "configs"]

lib_dir = File.expand_path('netomata')

Rake::TestTask.new('test') do |t|
    t.pattern = 'test/**/*.rb'
    t.libs = [lib_dir]
#   t.warning = true
end

desc "Generate test configs and diff against baseline"
task "configs" do
    sh 'rm -f sample/configs/switch-1.config sample/configs/switch-2.config'
    sh 'ncg -v sample/sample.neto'
    sh 'diff -u sample/configs/switch-1.baseline sample/configs/switch-1.config'
    sh 'diff -u sample/configs/switch-2.baseline sample/configs/switch-2.config'
    puts "Success!"
end

desc "Generate RDOC documentation"
task "rdoc" do
    sh 'rdoc -o rdoc lib/netomata.rb lib/netomata/'
end

desc "Check whether 'svn commit' or 'svn update' is needed"
task "svn_check" do
    puts "checking whether 'svn commit' or 'svn update' is needed..."
    unless IO.popen("svn status").readlines.length == 0
	fail ("#"*60 + "\n" +
	      "'svn status' is not clean; are there unchecked-in files?\n" +
	      "Need to do:\n\tsvn commit\n" +
	      "#"*60)
    end
    svn_info_rev = svn_revision()
    svn_info_head_rev = svn_revision("HEAD")
    unless (svn_info_rev == svn_info_head_rev)
	fail ("#"*60 + "\n" + 
	      "Version mismatch:\n" +
	      "\tsvn info\t\t=> #{svn_info_rev}" +
	      "\tsvn info -r HEAD\t=> #{svn_info_head_rev}" +
	      "Need to do:\n\tsvn update\n" +
	      "#"*60)
    end
end

desc "Snapshot current SVN trunk to demo tag"
task "tag_demo" => ["test", "configs", "svn_check"] do
    sh 'svn delete https://dev.netomata.com/svn/ncg/tags/demo -m "Removing old demo tag"'
    sh 'svn copy https://dev.netomata.com/svn/ncg/trunk https://dev.netomata.com/svn/ncg/tags/demo -m "Setting new demo tag"'
end

desc "Accept the current generated configs as the new baseline"
task "accept_baseline" => ["sample/configs/switch-1.config",
			    "sample/configs/switch-2.config"] do
    sh 'cp -p sample/configs/switch-1.config sample/configs/switch-1.baseline'
    sh 'cp -p sample/configs/switch-2.config sample/configs/switch-2.baseline'
end

dist_exclude_files = File.new("ignore.dist").readlines
dist_exclude_files.each { |l| l.chomp! }
dist_files = FileList['**/*']
dist_exclude_files.each { |e| dist_files.exclude(e) }
dist_files.exclude {|f| File.stat(f).directory? }

desc "Create a 'VERSION' file for distribution"
#task "VERSION" => ["svn_check"] do
task "VERSION" do
    puts "generating VERSION..."
    release = File.new("RELEASE").readline.chomp!
    build=svn_revision()
    v = File.new("VERSION", "w")
    v.truncate(0)
    v.puts("#{release}-#{build}")
    v.close
end

desc "Create all files for distribution"
task "dist" => ["dist_dir", "svn_check", "VERSION", "Manifest", "Versions", "dist_tar", "dist_tar_gz"]

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
task "Manifest" do
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
task "ignore.svn" do
    sh 'svn ps svn:ignore -F ignore.svn .'
end
