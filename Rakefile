$:.unshift("lib")

require "bundler/gem_tasks"
require "rake/testtask"
require "./lib/queue_classic"
require "./lib/queue_classic/tasks"

task :default => ['test']
Rake::TestTask.new do |t|
  t.libs << 'test'
  t.test_files = FileList['test/**/*_test.rb']
  t.verbose = true
  t.warning = true
end
