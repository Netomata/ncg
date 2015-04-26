# $Id$
# Copyright (C) 2008-2010 Netomata, Inc.  All Rights Reserved. 
# Please review accompanying 'LICENSE' file or
# http://www.netomata.com/docs/licenses/ncg for important notices,
# disclaimers, and license terms.

cwd = Dir.getwd
ENV["NETOMATA_LIB"] = File.expand_path(File.join(File.dirname(__FILE__),"lib"))

require 'rake/testtask'
require 'rubygems'
require 'rubygems/package_task'

def determine_git_branch
    # ## master => ""
    # ## whatever => whatever
    branch = IO.popen("git status -s -b -uno").grep(/^## /)[0].chomp!
    branch.sub!("## ", "")
    branch.sub!(/\.\.\..*/, "")
    if (branch.eql?("master")) then
	return ""
    else
	return branch
    end
end

def determine_git_hash(branch=nil)
    if branch.nil? then
	cmd = "git log -n 1 --pretty=format:%h"
    else
	cmd = "git log -n 1 --pretty=format:%h #{branch}"
    end

    hash = IO.popen(cmd).readline
    return hash
end

$git_hash=determine_git_hash()
$git_branch=determine_git_branch()

desc "Run all tests and generate/compare examples configs against baselines"
task "default" => ["test", "examples"]

lib_dir = File.expand_path('netomata')

desc "Run all tests"
task "test" => ["lib/netomata/version.rb", "do_test"]

Rake::TestTask.new("do_test") do |t|
    t.pattern = 'test/**/*.rb'
    t.libs = [lib_dir]
#   t.warning = true
end

desc "Generate examples configs and diff against baseline"
task "examples" => ["examples/switches", "examples/web_hosting"]

desc "Generate examples/switches configs and diff against baseline"
task "examples/switches" => ["lib/netomata/version.rb"] do
    sh 'rm -f examples/switches/configs/switch-1.config examples/switches/configs/switch-2.config'
    sh 'bin/ncg -v examples/switches/switches.neto'
    sh 'egrep -v "^!!" examples/switches/configs/switch-1.config | diff -u examples/switches/configs/switch-1.baseline -'
    sh 'egrep -v "^!!" examples/switches/configs/switch-2.config | diff -u examples/switches/configs/switch-2.baseline -'
    puts "#########################"
    puts "# examples/switches OK! #"
    puts "#########################"
end

desc "Generate examples/web_hosting configs and diff against baseline"
task "examples/web_hosting" => ["lib/netomata/version.rb"] do
    sh 'rm -rf examples/web_hosting/configs'
    sh 'bin/ncg -v examples/web_hosting/web_hosting.neto'
    sh 'egrep -v "^!!" examples/web_hosting/configs/switch-1.config | diff -u examples/web_hosting/configs-baseline/switch-1.config -'
    sh 'egrep -v "^!!" examples/web_hosting/configs/switch-2.config | diff -u examples/web_hosting/configs-baseline/switch-2.config -'
    sh 'egrep -v "^##" examples/web_hosting/configs/mrtg/mrtg.cfg | diff -u examples/web_hosting/configs-baseline/mrtg/mrtg.cfg -'
    sh "egrep -v '^\\$Id: |^ *Date: |^ *User: |^ *Host: |^ *Directory: |Expires' examples/web_hosting/configs/mrtg/index.html | diff -u examples/web_hosting/configs-baseline/mrtg/index.html -"
    sh 'cmp examples/web_hosting/configs-baseline/mrtg/netomata.logo.160x80.jpg examples/web_hosting/configs/mrtg/netomata.logo.160x80.jpg'
    sh 'cmp examples/web_hosting/configs-baseline/nagios/COMMON.cfg examples/web_hosting/configs/nagios/COMMON.cfg'
    sh 'diff -u examples/web_hosting/configs-baseline/nagios/switch-1.cfg examples/web_hosting/configs/nagios/switch-1.cfg'
    sh 'diff -u examples/web_hosting/configs-baseline/nagios/switch-2.cfg examples/web_hosting/configs/nagios/switch-2.cfg'
    puts "############################"
    puts "# examples/web_hosting OK! #"
    puts "############################"
end

desc "Generate docs from Netomata web site"
task "doc" => ["lib/netomata/version.rb"] do
    doc_release = File.new("dev/RELEASE").readline.chomp!
    # Docs track minor releases (x.y), not bugfix releases (x.y.z),
    # so convert doc_release from (for example) 0.10.1 to 0.10.x
    doc_release.gsub!(/\.[0-9]+$/, ".x")
    sh "dev/get_docs.rb -r #{doc_release}"
end

desc "Generate RDOC documentation"
task "rdoc" do
    sh 'rm -rf rdoc'
    sh 'rdoc -o rdoc -a lib/netomata.rb lib/netomata/'
end

desc "Accept the current generated examples configs as the new baseline"
task "examples_accept" do
    # fix examples/switches baselines
    sh "cp -p examples/switches/configs/switch-1.config examples/switches/configs/switch-1.baseline"
    sh "sed -e '/^!!/d' -i '' examples/switches/configs/switch-1.baseline"
    sh "cp -p examples/switches/configs/switch-2.config examples/switches/configs/switch-2.baseline"
    sh "sed -e '/^!!/d' -i '' examples/switches/configs/switch-2.baseline"
    # fix examples/web_hosting baselines
    sh 'egrep -v "^!!" examples/web_hosting/configs/switch-1.config > examples/web_hosting/configs-baseline/switch-1.config'
    sh 'egrep -v "^!!" examples/web_hosting/configs/switch-2.config > examples/web_hosting/configs-baseline/switch-2.config'
    sh 'egrep -v "^##" examples/web_hosting/configs/mrtg/mrtg.cfg > examples/web_hosting/configs-baseline/mrtg/mrtg.cfg'
    sh "egrep -v '^\\$Id: |^ *Date: |^ *User: |^ *Host: |^ *Directory: |Expires' examples/web_hosting/configs/mrtg/index.html > examples/web_hosting/configs-baseline/mrtg/index.html"
    sh 'cp examples/web_hosting/configs/mrtg/netomata.logo.160x80.jpg examples/web_hosting/configs-baseline/mrtg/netomata.logo.160x80.jpg'
    sh 'cp examples/web_hosting/configs/nagios/COMMON.cfg examples/web_hosting/configs-baseline/nagios/COMMON.cfg'
    sh 'cp examples/web_hosting/configs/nagios/switch-1.cfg examples/web_hosting/configs-baseline/nagios/switch-1.cfg'
    sh 'cp examples/web_hosting/configs/nagios/switch-2.cfg examples/web_hosting/configs-baseline/nagios/switch-2.cfg'
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
    elsif f.match(/\.gem$/)
	# exclude *.gem files
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
task "VERSION" do
    puts "generating VERSION..."
    release = File.new("dev/RELEASE").readline.chomp!
    v = File.new("VERSION", "w")
    v.truncate(0)
    if ($git_branch.eql?("")) then
	v.puts("#{release}-#{$git_hash}")
    else
	v.puts("#{release}-#{$git_hash}-#{$git_branch.sub(/^.*\//,"")}")
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
task "dist" => ["dist_dir", "VERSION", "lib/netomata/version.rb", "doc", "rdoc", "Manifest", "dist_tar", "dist_tar_gz"]

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
task "Manifest" => ["doc", "rdoc"]  do
    puts "generating Manifest..."
    m = File.new("Manifest", "w")
    m.truncate(0)
    dist_files.sort.each { |l|
	m.puts(l)
    }
    m.close
end

spec = Gem::Specification.new do |s| 
    s.name	= "ncg"
    s.summary	= "Netomata Config Generator"
    s.license	= "GPL-3.0"
    s.description = File.read(File.join(File.dirname(__FILE__), 'README'))
    s.requirements = 
      [ 'An installed dictionary (most Unix systems have one)' ]
    s.version	= 
      File.read(File.join(File.dirname(__FILE__), 'dev/RELEASE')).chomp!
    s.author	= "Brent Chapman"
    s.email	= "brent@netomata.com"
    s.homepage	= "http://www.netomata.com/tools/ncg"
    s.platform	= Gem::Platform::RUBY
    s.required_ruby_version = '>=1.9'
    s.files	= dist_files
    s.executables = [ "ncg" ]
    s.test_files = Dir["test/test*.rb"]
    s.has_rdoc	= true
    s.add_runtime_dependency 'hashery', '~> 2'
end

Gem::PackageTask.new(spec) { }
