require 'json'
require 'pg'
require 'uri'

$: << File.expand_path(__FILE__, 'lib')

require 'queue_classic/durable_array'
require 'queue_classic/database'
require 'queue_classic/worker'
require 'queue_classic/queue'
require 'queue_classic/api'
require 'queue_classic/job'

module QC
  extend Api
end

connection    = QC::Database.new(ENV["DATABASE_URL"],:top_boundry => ENV["TOP_BOUND"])
durable_array = QC::DurableArray.new(connection)

QC::Queue.instance.setup(:data_store => durable_array)
