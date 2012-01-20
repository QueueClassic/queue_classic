module QueueClassic
  #
  # A Producer puts items on to the Queue.
  #
  class Producer
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
  end
end
