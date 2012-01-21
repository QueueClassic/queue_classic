module QueueClassic
  #
  # A Consumer pulls items off of the Queue.
  #
  class Consumer
    # Create a new consumer
    #
    # session    - the Session object this Consumer is attached
    # queue_name - the name of the queue to consume from
    #
    # Returns the new Consumer object
    def initialize( session, queue_name )
      @session    = session
      @queue      = session.use_queue( queue_name )
    end

    #######
    private
    #######

    def connection
      @session.connection
    end
  end
end
