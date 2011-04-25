require 'json'
require 'pg'
require 'uri'

$: << File.expand_path("lib")

require 'queue_classic/durable_array'
require 'queue_classic/worker'
require 'queue_classic/queue'
require 'queue_classic/api'
require 'queue_classic/job'
require 'queue_classic/errors'

module QC
  extend Api
end

