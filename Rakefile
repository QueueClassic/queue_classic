$:.unshift("lib")

require "rake/testtask"
require "./lib/queue_classic"
require "./lib/queue_classic/tasks"

task :default => ['test']
Rake::TestTask.new do |t|
  t.libs << 'test'
  t.test_files = FileList['test/*_test.rb', 'test/lib/*_test.rb']
  t.verbose = true
  t.ruby_opts << "-rubygems" if RUBY_VERSION < "1.9"
end
