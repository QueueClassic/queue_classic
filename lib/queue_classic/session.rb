require 'queue_classic'
require 'queue_classic/connection'
require 'queue_classic/schema'
require 'queue_classic/queue'

module QueueClassic
  # A Session manages the Connection and is how Producers and Consumers are
  # created.
  #
  # A Session is the first object created when using QueueClassic
  #
  class Session
    include ::QueueClassic::Logable

    # The Producer instances that are associated with the session.
    attr_reader :producers

    # The Consumer instances that are associated with this session.
    attr_reader :consumers

    # The Connection used for this session
    attr_reader :connection

    # Connect to the given queue classic database
    #
    # database_url - url for connection, of the format postgres://user:password@host/database
    # schema_name  - the schema name to use. (default: queue_classic)
    #
    # Returns a new Session object
    def initialize( database_url, schema_name = Schema.default_schema_name )
      @db_url     = database_url
      @connection = QueueClassic::Connection.new( database_url )
      @schema     = QueueClassic::Schema.new( schema_name )
      @producers  = []
      @consumers  = []
      logger.info "connection uri = #{@db_url}"
      apply_connection_settings
    end

    # Disconnect from QueueClassic
    #
    def close
      @connection.close
    end

    # return the given Queue object.
    #
    # name - the name of the Queue object to return
    #
    # If the Queue does not exist then it is created.
    #
    # Returns a Queue object attached to this session
    def use_queue( name )
      rows = @connection.execute( "SELECT * FROM queues WHERE name = $1", name )
      if rows.empty? then
        rows = @connection.execute( "SELECT * FROM use_queue( $1 )", name )
      end
      return QueueClassic::Queue.new( self, rows.first['name'] )
    end

    # Return an array of all the Queue's in the system
    #
    def queues
      @connection.execute( "SELECT * FROM queues" ).map { |row|
        QueueClassic::Queue.new( self, row['name'] )
      }
    end

    # Return an instance of a Producer that is connected to the connection of
    # this session.
    #
    # name - the name of the queue this is a producer for.
    #
    # Returns an instance of Producer
    def producer_for( qname )
      prod = QueueClassic::Producer.new( self, qname )
      @producers << prod
      return prod
    end

    # Return an instance of a Consumer that is connected to a particular queue
    # in this session.
    #
    # name - the name of the queue that this Consumer is for.
    #
    # Returns an instance of Consumer
    def consumer_for( qname )
      consumer = QueueClassic::Consumer.new( self, qname )
      @consumers << consumer
      return consumer
    end

    #######
    private
    #######

    # Apply connection oriented settings.
    #
    def apply_connection_settings
      if @connection.schema_exist?( @schema.name ) then
        @connection.execute( "SET search_path TO #{@schema.name},public" )
        #execute( "select * from cleanup_stale_jobs()" )
      else
        raise QueueClassic::Error, "The Schema '#{@schema.name}' that you are attempting to connect to does not exist. Did you run QueueClassic::Bootstrap.setup( '#{@db_url}', '#{@schema.name}' )?"
      end
    end

  end
end
