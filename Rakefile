$: << File.expand_path("lib")
require 'rake'
require 'rake/testtask'

require 'queue_classic'
require 'queue_classic/tasks'

task :default => [:test_units]

desc "Run basic tests"
Rake::TestTask.new("test_units") { |t|
  t.pattern = 'test/*_test.rb'
  t.verbose = true
  t.warning = true
}
