require 'pg'
require 'json'
require 'uri'

module QueueClassic
  class Error < ::StandardError; end

  def self.db_path( *args )
    dir = File.expand_path("../../db", __FILE__)
    if args.size > 0 then
      return File.join( dir, *args )
    else
      return dir
    end
  end
end

require 'queue_classic/logable'
require 'queue_classic/producer'
require 'queue_classic/session'
require 'queue_classic/job'
