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

    # Reserve an from the queue. This gets an item from the queue and returns it
    #
    def reserve
      r = connection.execute("SELECT * FROM reserve($1)", @queue.name)
      return Message.new( r.first )
    end

    # Finalize a message. This removes a message from theq queue and puts it
    # into the messages_history table.
    #
    def finalize( msg, note )
      r = connection.execute( "SELECT * FROM finalize($1, $2, $3)", @queue.name, msg.id, note)
      return Message.new( r.first )
    end

    #######
    private
    #######

    def connection
      @session.connection
    end
  end
end
