module QueueClassic
  #
  # Schema holds the database meta information. It is what can install and tear
  # down what is needed in the database to support QueueClassic objects.
  #
  class Schema
    attr_reader :name

    class << self
      def default_schema_name
        'queue_classic'
      end
    end

    # Create a new database instance given the database schema for all the tables
    # in queue classic.
    def initialize( name = Schema.default_schema_name )
      @name = name
    end

    def tables_ddl
      IO.read( QueueClassic.db_path( "ddl.sql" ) )
    end

    def functions_ddl
      IO.read( QueueClassic.db_path( "functions.sql" ) )
    end
  end
end
