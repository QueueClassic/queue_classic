module QueueClassic
  # Encapsulate the data that is returned from a LISTEN/NOTIFY message 
  #
  # This is generally only used internally to the QueueClassic System itself
  class Notification
    # The channel the notification was sent on
    attr_reader :channel

    # The pid of the notifier
    attr_reader :pid

    # The message in the notification
    attr_reader :message

    # Create a new notification
    #
    def initialize( channel, pid, message )
      @channel = channel
      @message = message
      @pid     = pid
    end
  end
end
