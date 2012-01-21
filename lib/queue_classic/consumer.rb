module QueueClassic
  #
  # A Consumer pulls items off of the Queue.
  #
  class Consumer
    # The queue the consumer is attached to
    attr_reader :queue

    # The unique identifier of the consumer as determined by the connection
    attr_reader :consumer_id

    # Create a new consumer
    #
    # session    - the Session object this Consumer is attached
    # queue_name - the name of the queue to consume from
    #
    # Returns the new Consumer object
    def initialize( session, queue_name )
      @session    = session
      @queue      = session.use_queue( queue_name )
      @consumer_id = connection.apply_application_name( 'consumer' )
    end

    #######
    private
    #######

    def connection
      @session.connection
    end
  end
end
