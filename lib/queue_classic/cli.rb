require 'queue_classic'
require 'queue_classic/bootstrap'
require 'optparse'
require 'ostruct'

module QueueClassic
  # The commandline for QueueClassic.
  #
  # There are several operations that are useful to execute outside the context
  # of the core library. Specifically, initializing the database and the schema
  # for use by the library itself.
  class CLI
    def initialize
      @options = OpenStruct.new
      @options.schema = QueueClassic::Schema.default_schema_name
    end

    def parser
      OptionParser.new do |opts|
        opts.banner = "Usage: queue_classic [options] COMMAND"

        opts.separator ""
        opts.separator "Options:"

        opts.on("-d", "--database [URL]", "The database connection url",
                                          "Example: postgresql://user:pass@localhost/queue_classic") do |url|
          @options.db_url = url
        end

        opts.on("-s", "--schema [SCHEMA]", "The schema to use for queue_classic",
                                           "Default: #{@options.schema}") do |schema|
          @options.schema = schema
       end

        opts.on("-v", "--verbose", "Be more verbose") do
          $VERBOSE = true
          @options.verbose = true
        end

        opts.on("-h", "--help", "Show this message") do
          $stderr.puts opts
          exit
        end

        opts.separator ""
        opts.separator "Commands:"
        opts.separator "  setup     Creates the table and functions in the database"
        opts.separator "  teardown  Destroyes the tables and functions in the database"
      end
    end

    # Run the commandline
    #
    # argv - the commandline arguments to parse
    # env  - the environment
    #
    def run( argv = ARGV, env = ENV )
      parser.parse!
      case command = argv.shift
      when 'setup'
        QueueClassic::Bootstrap.setup( @options.db_url, @options.schema )
        $stdout.puts "QueueClassic tables and functions installed into database #{@options.db_url} at schema #{@options.schema}"
      when 'teardown'
        QueueClassic::Bootstrap.teardown( @options.db_url, @options.schema )
        $stdout.puts "QueueClassic tables and functions removed from database #{@options.db_url} at schema #{@options.schema}"
      when nil
        abort "A Command is required, see --help"
      else
        abort "Unknown command '#{command}'. See --help"
      end
    end
  end
end
