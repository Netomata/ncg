require 'rake/testtask'

lib_dir = File.expand_path('netomata')

desc "Run all tests and generate/compare configs against baselines"
task "default" => ["test", "configs"]

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
    sh 'rdoc netomata.rb netomata/'
end

desc "Snapshot current SVN trunk to demo tag"
task "tag_demo" => ["test", "configs"] do
    svn_status = `svn status`
    unless svn_status.empty?
	fail "#"*60 + "\n" + "'svn status' is not clean; are there unchecked-in files?\n" + "#"*60
    end
    sh 'svn delete https://dev.netomata.com/svn/ncg/tags/demo -m "Removing old demo tag"'
    sh 'svn copy https://dev.netomata.com/svn/ncg/trunk https://dev.netomata.com/svn/ncg/tags/demo -m "Setting new demo tag"'
end

desc "Accept the current generated configs as the new baseline"
task "accept_baseline" => ["sample/configs/switch-1.config",
			    "sample/configs/switch-2.config"] do
    sh 'cp -p sample/configs/switch-1.config sample/configs/switch-1.baseline'
    sh 'cp -p sample/configs/switch-2.config sample/configs/switch-2.baseline'
end

