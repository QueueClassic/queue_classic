module QueueClassic
  # The Queue represents a single connection to a Single queue in the system.
  # You can do diferent operations on a queue:
  #
  class Queue

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

    # Return how many items are in the queue
    #
    def size
      row = connection.execute(" SELECT queue_size($1)", @name )
      return row.first['queue_size'].to_i
    end

    # Return how many items are in the queue that are ready
    #
    def ready_size
      row = connection.execute( "SELECT queue_ready_size($1)", @name )
      return row.first['queue_ready_size'].to_i
    end

    # Return how many items are in the queue that are reserved
    #
    def reserved_size
      row = connection.execute( "SELECT queue_reserved_size($1)", @name )
      return row.first['queue_reserved_size'].to_i
    end


    #######
    private
    #######

    def connection
      @session.connection
    end

  end
end
