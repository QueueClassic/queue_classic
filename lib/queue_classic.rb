require 'bundler'
Bundler.setup
Bundler.require

dir = Pathname(__FILE__).dirname.expand_path
require dir + 'queue_classic/durable_array'
require dir + 'queue_classic/queue'
require dir + 'queue_classic/api'

module QC
  extend Api
end
