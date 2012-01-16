module QueueClassic
  # A Connection encapsulates a single connection to a particular postgresql
  # database.
  class Connection
    include ::QueueClassic::Logable

    attr_reader :db_url

    # Connect to the given queue classic database
    #
    # database_url - url for connection, of the format postgres://user:password@host/database
    # schema_name  - the schema name to use. (default: queue_classic)
    #
    # Returns a new Connection object
    def initialize( database_url, schema_name = Schema.default_schema_name )
      @db_url    = database_url
      @db_params = URI.parse( @db_url )
      @schema    = QueueClassic::Schema.new( schema_name )
      logger.info "connection uri = #{db_url}"
      connection
    end

    # Connect to the database if we are not already connected
    #
    # Returns the PGconn object
    def connection
      @connection ||= connect
    end

    # Disconnect from the database
    #
    # Returns nothing
    def disconnect
      connection.finish
      @connection = nil
    end

    # Execute the give sql with the substitution parameters
    #
    # sql    - the sql statement to execute
    # params - the params to substitute into the statment
    #
    # Returns the PGresult
    def execute(sql, *params)
      logger.debug("executing #{sql.inspect}, #{params.inspect}")
      begin
        params = nil if params.empty?
        connection.exec(sql, params)
      rescue PGError => e
        logger.error("execute exception=#{e.inspect}")
        raise
      end
    end

    #######
    private
    #######

    # Establish an actual connection to the Postgres database and return the
    # PGConn object
    #
    # Returns a PGConn object
    def connect
      logger.info "establishing connection"
      conn = PGconn.connect(
        @db_params.host,
        @db_params.port || 5432,
        nil, #opts
        '',  #tty
        @db_params.path.gsub("/",""), #database name
        @db_params.user,
        @db_params.password
      )
      if conn.status != PGconn::CONNECTION_OK
        logger.error("connection error=#{conn.error}")
        raise QueueClassic::Error, "Error on connection #{conn.error}"
      end
      conn
    end
  end
end
