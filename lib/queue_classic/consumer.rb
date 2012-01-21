module QueueClassic
  #
  # A Consumer pulls items off of the Queue.
  #
  class Consumer
    # The queue the consumer is attached to
    attr_reader :queue

    # The unique identifier of the consumer as determined by the connection
    attr_reader :consumer_id

    # The connection for this Consumer
    attr_reader :connection

    # Create a new consumer
    #
    # session    - the Session object this Consumer is attached
    # queue_name - the name of the queue to consume from
    #
    # Returns the new Consumer object
    def initialize( session, queue_name )
      @session     = session
      @queue       = session.use_queue( queue_name )
      @connection  = session.clone_connection
      @consumer_id = connection.apply_application_name( 'consumer' )
    end

    # Reserve an from the queue. This gets an item from the queue and returns it
    #
    def reserve
      r = connection.execute("SELECT * FROM reserve($1)", @queue.name)
      return nil if r.empty?
      return Message.new( r.first )
    end

    # Yield each message that is currently on the queue
    #
    # This will reserve a message, yield it and then automatically finalize it
    # if there were no exceptions during the processing of it. If there were
    # errors during hte processing of the message those will be propogated up
    # the stack.
    #
    # Returns nothing
    def each_message
      while message = reserve() do
        yield message
        finalize( message, "automatically finalized" )
      end
    end

    # Finalize a message. This removes a message from theq queue and puts it
    # into the messages_history table.
    #
    def finalize( msg, note )
      r = connection.execute( "SELECT * FROM finalize($1, $2, $3)", @queue.name, msg.id, note)
      return Message.new( r.first )
    end

    # Close the consumer, unhooking its connection
    #
    def close
      @connection.close
    end

    # Wait for an item to be on the queue, and then return it
    #
    # def wait_for_reserve
      # return msg if msg = reserve()
      # connection.listen( @queue.name )
      # return m if m
      # return
      # loop do
      # end
    # end
  end
end
