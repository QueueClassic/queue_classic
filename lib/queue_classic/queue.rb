module QueueClassic
  # The Queue represents a single connection to a Single queue in the system.
  # You can do diferent operations on a queue:
  #
  class Queue

    # the name of this queue
    attr_reader :name

    def initialize( connection, name )
      @connection = connection
      @name       = name
    end
  end
end
