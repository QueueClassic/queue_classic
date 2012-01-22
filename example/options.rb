require 'queue_classic'
require 'optparse'
require 'ostruct'

begin
  require 'hitimes'
rescue LoadError
  abort "This example script uses hitimes to output some metrics, so `gem install hitimes`"
end

class ExampleCLI

  attr_reader :options

  def initialize
    @options = OpenStruct.new
    @options.db_url = 'postgres:///queue_classic'
    @options.queue  = 'classic'
    @options.count  = 10_000
  end

  def parser
    OptionParser.new do |opts|
      opts.banner = "Usage: #{$0} [options]"

      opts.separator ""
      opts.separator "Options:"

      opts.on("-d", "--database [URL]", "The database connection url",
                                      "Default: #{@options.db_url}") do |url|
        @options.db_url = url
      end

      opts.on("-q", "--queue [QUEUE]", "The queue to connect to", 
                                     "Default: #{@options.queue}") do |queue|
        @options.queue = queue
      end

      opts.on "-c", "--count [COUNT]", "The number of messages to put on the queue",
                                     "Default: #{@options.count} )" do |count|
        @options.count = count.to_i
      end

      opts.on("-h", "--help", "Show this message") do
        $stderr.puts opts
        exit
      end
    end
  end
end
