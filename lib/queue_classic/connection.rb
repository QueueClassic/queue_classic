require 'queue_classic/notification'

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
    class ClosedError < ::QueueClassic::Error; end

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
      if @connection then
        notifications # drain notifications
        @connection.finish
        @connection = nil
      end
    end

    # Is this connection live?
    #
    def connected?
      @connection
    end

    # Execute the give sql with the substitution parameters
    #
    # sql    - the sql statement to execute
    # params - the params to substitute into the statment
    #
    # Returns true if there
    def execute(sql, *params)
      raise ClosedError, "This connection to host '#{db_host}', database '#{db_name}' is closed." unless connected?
      logger.debug("executing #{sql.inspect}, #{params.inspect}")
      params = nil if params.empty?
      result_to_array_of_hashes( @connection.exec(sql, params) )
    rescue PGError => e
      logger.error("execute exception=#{e.inspect}")
      raise
    end

    # Show what the search path is for the current connection
    #
    def search_path
      execute("SHOW search_path").first['search_path']
    end

    # Set the search path to the given value
    #
    # path - the string to set the search_path to.
    #
    # Returns the new search_path
    def search_path=( path )
      execute("SET search_path TO #{path}")
      return search_path()
    end

    # Show what the application name is of the current connection
    #
    # Return the string application name
    def application_name
      execute("SHOW application_name").first['application_name']
    end

    # Set the application name to the given value
    #
    # name - the string to set the application_name to.
    #
    # Returns the new application_name
    def application_name=( app_name )
      execute("SET application_name TO '#{app_name}'")
      return application_name()
    end

    # Check and see if the schema name give on initialization exists in the
    # database.
    #
    # Returns true or false
    def schema_exist?( schema_name )
      result = execute("SELECT count(*)::int FROM pg_namespace where nspname = $1", schema_name )
      return (result[0]['count'].to_i >= 1)
    end

    # Generate a unique applicaiton name based upon the input stem
    #
    # Returns the application name
    def generate_application_name( stem )
      result = execute("SELECT application_id( $1 )", stem)
      return result.first['application_id']
    end

    # Apply an unique application name to the current connection
    #
    def apply_application_name( stem )
      app_name = generate_application_name( stem )
      self.application_name = app_name
    end

    # Listen on the connection for notifications on the given channel
    #
    def listen( channel )
      execute("LISTEN #{channel}")
    end

    # Stop listening on the given channel
    #
    def unlisten( channel )
      execute("UNLISTEN #{channel}")
    end

    # Wait for a notification
    #
    def wait_for_notification( timeout )
      notification = nil
      @connection.wait_for_notify( timeout ) do |channel, pid, msg|
        notification = QueueClassic::Notification.new( channel, pid, msg )
      end
      return notification
    end

    # Send a notification on the given channel
    #
    def notify(channel, message = nil )
      sql ="NOTIFY #{channel}"
      sql += ", '#{message}'" if message
      execute( sql )
    end

    # Return an Array of all the notifications left in the connection. If there
    # are no notifications left, an empty array is retured.
    #
    # should_wait - should a small wait be done to see if some notifications
    #               show up before returning all the notifications?
    #               (default: false)
    #
    # Return an Array of all the notifications, it may be empty.
    def notifications( should_wait = false)
      notifications = []
      if should_wait then
        n = wait_for_notification( 1 )
        notifications << n if n
      end

      while n = @connection.notifies do
        notifications << new_notification( n )
      end
      return notifications
    end

    # Yield each notification that is still in the connection
    #
    # should_wait - should a small wait be done first to see if
    #               there are notifications that need to be collected by the pg
    #               adapter? ( default: false )
    #
    def each_notification( should_wait = false, &block)
      if should_wait then
        n = wait_for_notification( 1 )
        yield n
      end

      while n = @connection.notifies do
        yield new_notification( n )
      end
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

    # Create a new Notification from the hash that is returned from
    # PGconn#notifies
    #
    def new_notification( h )
      QueueClassic::Notification.new( h[:relname], h[:be_pid], h[:extra] )
    end

    def db_name
      @db_params.path.gsub("/","")
    end

    def db_host
      @db_params.host
    end

    # Establish an actual connection to the Postgres database and return the
    # PGConn object
    #
    # Returns a PGConn object
    def connect
      logger.info "establishing connection"
      conn = PGconn.connect(
        db_host,
        @db_params.port || 5432,
        nil, #opts
        '',  #tty
        db_name,
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
