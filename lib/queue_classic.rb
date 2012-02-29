require "pg"

require "logger"
require "uri"

$: << File.expand_path(__FILE__, "lib")

require "queue_classic/okjson"
require "queue_classic/durable_array"
require "queue_classic/database"
require "queue_classic/worker"
require "queue_classic/logger"
require "queue_classic/queue"
require "queue_classic/job"

module QC
  VERBOSE = ENV["VERBOSE"] || ENV["QC_VERBOSE"]
  Logger.puts("Logging enabled")

  def self.method_missing(sym, *args, &block)
    Queue.send(sym, *args, &block)
  end
end
