require 'rake/testtask'

lib_dir = File.expand_path('netomata')

task "default" => ["test", "configs"]

Rake::TestTask.new('test') do |t|
    t.pattern = 'test/**/*.rb'
    t.libs = [lib_dir]
#   t.warning = true
end

desc "Generate test configs and diff against baseline"
task "configs" do
    sh 'ncg'
    sh 'diff sample/configs/switch-1.baseline sample/configs/switch-1.config'
    sh 'diff sample/configs/switch-2.baseline sample/configs/switch-2.config'
end
