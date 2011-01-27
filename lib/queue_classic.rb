require 'bundler'
Bundler.setup
Bundler.require

dir = Pathname(__FILE__).dirname.expand_path
require dir + 'queue_classic/durable_array'
require dir + 'queue_classic/queue'
require dir + 'queue_classic/api'
require dir + 'queue_classic/worker'

ENV["DATABASE_URL"] = "queue_classic_test"

QC::Queue.setup :data_store => QC::DurableArray.new(:dbname => ENV["DATABASE_URL"])

module QC
  extend Api
end
