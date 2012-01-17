require 'queue_classic/pg_connection'
module QueueClassic
  # Bootstrap the schema of the QueueClassic system.
  #
  # This is used to install/setup or remove/teardown the database schema
  #
  class Bootstrap
    include QueueClassic::Logable

    def self.setup( database_url, schema = ::QueueClassic::Schema.default_schema_name )
      bs = Bootstrap.new( database_url, schema )
      if not bs.schema_exist?( schema ) then
        bs.setup
      else
        Logable.logger.error("Schema #{schema} already exists")
      end
      return bs
    end

    def self.teardown( database_url, schema = ::QueueClassic::Schema.default_schema_name )
      bs = Bootstrap.new( database_url, schema )
      if bs.schema_exist?( schema ) then
        bs.teardown
      end
      return nil
    end

    attr_reader :conn

    def initialize( database_url, schema = ::QueueClassic::Schema.default_schema_name )
      @conn        = QueueClassic::PGConnection.new( database_url )
      @schema_name = schema
      @schema      = QueueClassic::Schema.new( @schema_name )
    end

    def schema_exist?( name )
      @conn.schema_exist?( name )
    end

    # Check and see if the table name given exists in the database in the schema
    # of this connection
    #
    # Returns true or false
    def table_exist?( schema_name, table_name )
      @conn.table_exist?( schema_name, table_name)
    end

    def setup
      @conn.execute( "CREATE SCHEMA #{@schema_name}" )
      @conn.execute( "SET search_path TO #{@schema_name},public" )
      logger.info "Installing tables"
      @conn.execute( @schema.tables_ddl )
      logger.info "Installing functions"
      @conn.execute( @schema.functions_ddl )
    end

    def teardown
      @conn.execute( "DROP SCHEMA #{@schema_name} CASCADE" )
    end
  end
end
