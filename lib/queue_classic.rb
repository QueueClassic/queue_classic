require 'json'
require 'pg'
require 'uri'

$: << File.expand_path(__FILE__, 'lib')

require 'queue_classic/durable_array'
require 'queue_classic/worker'
require 'queue_classic/queue'
require 'queue_classic/api'
require 'queue_classic/job'
require 'queue_classic/database_helpers'

module QC
  extend Api
  class Helper
    extend DatabaseHelpers
  end
end

QC::Helper.load_functions
QC::Queue.instance.setup :data_store => QC::DurableArray.new(ENV['DATABASE_URL'])
