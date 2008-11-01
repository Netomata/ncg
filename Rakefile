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
    sh 'rm sample/configs/switch-1.config sample/configs/switch-2.config'
    sh 'ncg'
    sh 'diff -u sample/configs/switch-1.baseline sample/configs/switch-1.config'
    sh 'diff -u sample/configs/switch-2.baseline sample/configs/switch-2.config'
end

desc "Snapshot current SVN trunk to demo tag"
task "tag_demo" => ["test", "configs"] do
    sh 'svn delete https://dev.netomata.com/svn/ncg/tags/demo -m "Removing old demo tag"'
    sh 'svn copy https://dev.netomata.com/svn/ncg/trunk https://dev.netomata.com/svn/ncg/tags/demo -m "Setting new demo tag"'
end
