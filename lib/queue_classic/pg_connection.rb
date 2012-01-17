module QueueClassic
  # PGConnection is the minimal amount of overhead to make a ::PGconn object
  # usable from within QueueClassic
  class PGConnection
    include QueueClassic::Logable

    attr_reader :db_url

    def initialize( database_url )
      @db_url    = database_url
      @db_params = URI.parse( @db_url )
      logger.info "connection uri = #{@db_url}"
      @connection = connect
      execute( "SET client_min_messages TO 'warning'" )
    end

    # Disconnect from the database
    #
    # Returns nothing
    def disconnect
      @connection.finish
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
        @connection.exec(sql, params)
      rescue PGError => e
        logger.error("execute exception=#{e.inspect}")
        raise
      end
    end

    # Check and see if the schema name give on initialization exists in the
    # database.
    #
    # Returns true or false
    def schema_exist?( schema_name )
      result = execute("SELECT count(*)::int FROM pg_namespace where nspname = $1", schema_name )
      return (result[0]['count'].to_i >= 1)
    end

    #######
    private

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
      return conn
    end
  end
end
