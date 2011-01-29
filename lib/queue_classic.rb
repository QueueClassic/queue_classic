require 'json'
require 'pg'

require_relative "queue_classic/durable_array"
require_relative "queue_classic/worker"
require_relative "queue_classic/queue"
require_relative "queue_classic/api"

ENV["DATABASE_URL"] = "queue_classic_test"

class Notifier
  def self.deliver(msg)
    `say #{msg}`
  end
end

QC::Queue.setup :data_store => QC::DurableArray.new(:dbname => ENV["DATABASE_URL"])

module QC
  extend Api
end
