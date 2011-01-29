require 'json'
require 'pg'

$: << File.expand_path("lib")

require 'queue_classic/durable_array'
require 'queue_classic/worker'
require 'queue_classic/queue'
require 'queue_classic/api'

QC::Queue.setup :data_store => QC::DurableArray.new(:dbname => ENV["DATABASE_URL"])

module QC
  extend Api
end
