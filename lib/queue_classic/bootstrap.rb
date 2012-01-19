require 'queue_classic/connection'
require 'queue_classic/schema'

module QueueClassic
  #
  # Bootstrap is a one use class that is invoked by the commandline when setting
  # up and tearing down the tables involved in the QueueClassic system
  #
  class Bootstrap
    include QueueClassic::Logable

    # Helper method to boostrap QueueClassic
    #
    # Returns nothing.
    def self.setup( database_url, schema = ::QueueClassic::Schema.default_schema_name )
      bs = Bootstrap.new( database_url, schema )
      if not bs.schema_exist?( schema ) then
        bs.setup
      else
        Logable.logger.error("Schema #{schema} already exists")
      end
      return bs
    end

    # Helper method to teardown QueueClassic
    #
    # Returns nothing.
    def self.teardown( database_url, schema = ::QueueClassic::Schema.default_schema_name )
      bs = Bootstrap.new( database_url, schema )
      if bs.schema_exist?( schema ) then
        bs.teardown
      end
      return nil
    end

    # Create a new Boostrap object.
    #
    # database_url - the url of the database to connect to
    # schema       - the schema under which to create the tables.
    #                (default: 'queue_classic')
    #
    # Returns the new Boostrap object.
    def initialize( database_url, schema = ::QueueClassic::Schema.default_schema_name )
      @conn        = QueueClassic::Connection.new( database_url )
      @schema_name = schema
      @schema      = QueueClassic::Schema.new( @schema_name )
    end

    # See if the given String is a schema in the database
    #
    # name - the schema to check
    #
    # Returns true or false based upon the existence of the schema
    def schema_exist?( name )
      @conn.schema_exist?( name )
    end

    # Check and see if the table name given exists in the database in the schema
    # of this connection.
    #
    # This method is really only used for testing to make sure that the tables
    # are setup.
    #
    # Returns true or false
    def table_exist?( schema_name, table_name )
      @conn.table_exist?( schema_name, table_name)
    end

    # Setup the SQL tables and functions necessary to utilize QueueClassic.
    #
    # This creates the schema, and the installs the tables and functions into
    # that schema.
    #
    # Returns nothing.
    def setup
      @conn.execute( "CREATE SCHEMA #{@schema_name}" )
      @conn.execute( "SET search_path TO #{@schema_name},public" )
      logger.info "Installing tables"
      @conn.execute( @schema.tables_ddl )
      logger.info "Installing functions"
      @conn.execute( @schema.functions_ddl )
    end

    # Delete the entire database schema that is used by QueueClassic, absolutely
    # removing the schema, tables and functions.
    #
    # Returns nothing.
    def teardown
      @conn.execute( "DROP SCHEMA #{@schema_name} CASCADE" )
    end
  end
end
