require 'queue_classic/pg_connection'
module QueueClassic
  # A Connection encapsulates a single connection to a particular postgresql
  # database.
  class Connection
    include ::QueueClassic::Logable

    attr_reader :schema

    # Connect to the given queue classic database
    #
    # database_url - url for connection, of the format postgres://user:password@host/database
    # schema_name  - the schema name to use. (default: queue_classic)
    #
    # Returns a new Connection object
    def initialize( database_url, schema_name = Schema.default_schema_name )
      @pg_conn = QueueClassic::PGConnection.new( database_url )
      @schema  = QueueClassic::Schema.new( schema_name )
      logger.info "connection uri = #{db_url}"
      apply_connection_settings
    end

    # Return the db_url
    def db_url
      @pg_conn.db_url
    end

    # Check and see if the schema name give on initialization exists in the
    # database.
    #
    # Returns true or false
    def schema_exist?( schema_name = @schema.name )
      @pg_conn.schema_exist?( schema_name )
    end

    # Check and see if the table name given exists in the database in the schema
    # of this connection
    #
    # Returns true or false
    def table_exist?( table_name )
      @pg_conn.table_exist?( @schema.name, table_name )
    end


    # Execute the sql statement given the query and params
    #
    def execute( sql, *params )
      @pg_conn.execute(sql, *params)
    end

    # Disconnect from the database
    #
    def disconnect
      @pg_conn.disconnect
    end

    #######
    private

    # Connect to the database if we are not already connected
    #
    # Returns the PGconn object
    def apply_connection_settings
      if schema_exist? then
        execute( "SET search_path TO #{@schema.name},public" )
      else
        raise QueueClassic::Error, "The Schema '#{@schema.name}' that you are attempting to connect to does not exist. Did you run QueueClassic::Bootstrap.setup( '#{db_url}', '#{@schema.name}' )?"
      end
    end

  end
end
