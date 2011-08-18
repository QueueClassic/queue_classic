require 'json'
require 'pg'
require 'uri'

$: << File.expand_path(__FILE__, 'lib')

require 'queue_classic/durable_array'
require 'queue_classic/database'
require 'queue_classic/worker'
require 'queue_classic/queue'
require 'queue_classic/job'

module QC

  USE_PUB_SUB = ENV["QC_USE_PUB_SUB"] == "true"

  def self.method_missing(sym, *args, &block)
    Queue.send(sym, *args, &block)
  end
end
