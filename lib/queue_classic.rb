require 'json'
require 'pg'

$: << File.expand_path("lib")

require 'queue_classic/durable_array'
require 'queue_classic/worker'
require 'queue_classic/queue'
require 'queue_classic/api'

module QC
  extend Api
end

QC::Queue.setup :data_store => QC::DurableArray.new(:database => ENV["DATABASE_URL"])
