module QueueClassic
  #
  # A Producer puts items on to the Queue.
  #
  class Producer
    def initialize( session, queue_name )
      @session = session
      @queue   = session.use_queue( queue_name )
    end
  end
end
