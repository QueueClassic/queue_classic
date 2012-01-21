module QueueClassic
  #
  # A Producer puts items on to the Queue.
  #
  class Producer
    # The queue the producer is attached to
    attr_reader :queue

    # Create a new producer
    #
    # session    - the Session object this producer is attached
    # queue_name - the name of the queue to put items onto
    #
    # Returns the new producer object
    def initialize( session, queue_name )
      @session = session
      @queue   = session.use_queue( queue_name )
    end

    # Put a message onto the queue
    #
    # obj - the Object to be put onto the queue. #to_s will be called on this to
    #       convert it to a string for serialization
    #
    # Returns the id
    def put( obj )
      result = connection.execute( "SELECT * from put( $1, $2)", @queue.name, obj.to_s )
      return result.first['id'].to_i
    end

    #######
    private
    #######

    def connection
      @session.connection
    end
  end
end
