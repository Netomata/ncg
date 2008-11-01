require 'rake/testtask'

lib_dir = File.expand_path('netomata')

Rake::TestTask.new('test') do |t|
    t.pattern = 'test/**/*.rb'
    t.libs = [lib_dir]
#   t.warning = true
end

task "default" => ["test", "configs"]


task "configs" do
    sh 'ncg'
    sh 'diff sample/configs/switch-1.baseline sample/configs/switch-1.config'
    sh 'diff sample/configs/switch-2.baseline sample/configs/switch-2.config'
end
