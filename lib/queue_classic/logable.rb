require 'logger'
module QueueClassic
  module Logable
    def ruby_logger
      if not defined? @logger then
        @logger = ::Logger.new( $stderr )
        if $VERBOSE || ENV['VERBOSE'] then
          @logger.level = ::Logger::DEBUG
        else
          @logger.level = ::Logger::WARN
        end
      end
      return @logger
    end

    def logger
      ruby_logger
    end

    extend self
  end
end
