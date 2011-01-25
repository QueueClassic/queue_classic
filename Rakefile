require 'rake'
require "rspec/core/rake_task"

$:.unshift File.expand_path("../lib", __FILE__)
require "queue_classic"

task :default => :spec
desc "Run all specs"
RSpec::Core::RakeTask.new(:spec) do |t|
  t.pattern = 'spec/**/*_spec.rb'
end
