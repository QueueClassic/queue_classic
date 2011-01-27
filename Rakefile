require 'rake'
require "rspec/core/rake_task"

$:.unshift File.expand_path("../lib", __FILE__)
require "queue_classic"

task :default => :spec
desc "Run all specs"
RSpec::Core::RakeTask.new(:spec) do |t|
  t.pattern = 'spec/**/*_spec.rb'
end


require File.join(File.dirname(__FILE__), 'spec', 'database_helpers')

namespace :db do
  task :reset do
    include DatabaseHelpers
    drop_database
  end
  task :table do
    include DatabaseHelpers
    drop_table
    create_table
  end
end
