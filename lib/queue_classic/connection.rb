module QueueClassic
  #
  # Connection is the minimal amount of overhead to make a ::PGconn object
  # usable from within QueueClassic.
  #
  # This class is not normally used by anyone using this library. It is an
  # internal class.
  #
  class Connection
    include QueueClassic::Logable

    # Create a new Connection object that connects to the given db_url
    #
    # db_url - a database url to connect to
    #          The format is -> postgresql://user:password@host/database
    #
    # Returns the Connection
    def initialize( database_url )
      @db_url    = database_url
      @db_params = URI.parse( @db_url )
      logger.info "connection uri = #{@db_url}"
      @connection = connect
      execute( "SET client_min_messages TO 'warning'" )
    end

    # Close the database connect
    #
    # Returns nothing
    def close
      @connection.finish
      @connection = nil
    end

    # Execute the give sql with the substitution parameters
    #
    # sql    - the sql statement to execute
    # params - the params to substitute into the statment
    #
    # Returns true if there 
    def execute(sql, *params)
      logger.debug("executing #{sql.inspect}, #{params.inspect}")
      begin
        params = nil if params.empty?
        result_to_array_of_hashes( @connection.exec(sql, params) )
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

    # Check and see if the table name given exists in the database in the given
    # schema
    #
    # Returns true or false
    def table_exist?( schema_name, table_name )
      result = execute(<<-_sql_, schema_name, table_name)
      SELECT n.nspname, c.relname, count(*)::int
        FROM pg_class AS c
        JOIN pg_namespace AS n
          ON n.oid = c.relnamespace
       WHERE n.nspname = $1
         AND c.relname = $2
    GROUP BY n.nspname, c.relname
      _sql_
      return (result[0]['count'].to_i >= 1)
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
      return conn
    end

    # Convert a PGresult into something that is more usable by the rest of ruby
    #
    # pgresult - a PGresult object
    #
    # If PGresult was a non-row-returning statement, then return an empty array.
    # Otherwise, return an array of hashes.
    #
    def result_to_array_of_hashes( pgresult )
      return [] if pgresult.ntuples == 0
      return pgresult.to_a
    end
  end
end
