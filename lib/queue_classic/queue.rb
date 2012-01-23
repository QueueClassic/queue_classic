module QueueClassic
  # The Queue represents a single connection to a Single queue in the system.
  # You can do diferent operations on a queue:
  #
  class Queue

    def self.default_name
      "classic"
    end

    # the name of this queue
    attr_reader :name

    # Create a new queue
    #
    # session - the Session to use for introspection
    # name    - the name of the queue
    def initialize( session , name )
      @session = session
      @name    = name
    end

    # Return how many items are in the queue, this is the sum of the ready_count
    # and the reserved_count
    #
    def processing_count
      row = connection.execute(" SELECT queue_processing_count($1)", @name )
      return row.first['queue_processing_count'].to_i
    end

    # Return how many items are in the queue that are ready
    #
    def ready_count
      row = connection.execute( "SELECT queue_ready_count($1)", @name )
      return row.first['queue_ready_count'].to_i
    end

    # Return how many items are in the queue that are reserved
    #
    def reserved_count
      row = connection.execute( "SELECT queue_reserved_count($1)", @name )
      return row.first['queue_reserved_count'].to_i
    end

    # Return how many items are from this queue
    #
    def finalized_count
      row = connection.execute( "SELECT queue_finalized_count($1)", @name )
      return row.first['queue_finalized_count'].to_i
    end

    #######
    private
    #######

    def connection
      @session.connection
    end

  end
end
