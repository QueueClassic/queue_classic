require 'queue_classic/pg_connection'
module QueueClassic
  # Bootstrap the schema of the QueueClassic system.
  #
  # This is used to install/setup or remove/teardown the database schema
  #
  class Bootstrap
    def self.setup( database_url, schema = ::QueueClassic::Schema.default_schema_name )
      bs = Bootstrap.new( database_url, schema )
      if not bs.schema_exist?( schema ) then
        bs.setup
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

    def setup
      @conn.execute( "CREATE SCHEMA #{@schema_name}" )
      @conn.execute( "SET search_path TO #{@schema_name},public" )
      @conn.execute( @schema.tables_ddl )
      @conn.execute( @schema.functions_ddl )
    end

    def teardown
      @conn.execute( "DROP SCHEMA #{@schema_name} CASCADE" )
    end
  end
end
