require 'queue_classic/connection'
require 'queue_classic/schema'

module QueueClassic
  # A Session manages the Connection and is how Producers and Consumers are
  # created.
  #
  # A Session is the first object created when using QueueClassic
  #
  class Session
    include ::QueueClassic::Logable

    # Connect to the given queue classic database
    #
    # database_url - url for connection, of the format postgres://user:password@host/database
    # schema_name  - the schema name to use. (default: queue_classic)
    #
    # Returns a new Session object
    def initialize( database_url, schema_name = Schema.default_schema_name )
      @db_url = database_url
      @conn   = QueueClassic::Connection.new( database_url )
      @schema = QueueClassic::Schema.new( schema_name )
      logger.info "connection uri = #{@db_url}"
      apply_connection_settings
    end

    # Disconnect from QueueClassic
    #
    def close
      @conn.close
    end

    #######
    private
    #######

    # Apply connection oriented settings.
    #
    def apply_connection_settings
      if @conn.schema_exist?( @schema.name ) then
        @conn.execute( "SET search_path TO #{@schema.name},public" )
        #execute( "select * from cleanup_stale_jobs()" )
      else
        raise QueueClassic::Error, "The Schema '#{@schema.name}' that you are attempting to connect to does not exist. Did you run QueueClassic::Bootstrap.setup( '#{@db_url}', '#{@schema.name}' )?"
      end
    end

  end
end
