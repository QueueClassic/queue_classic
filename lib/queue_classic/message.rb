module QueueClassic
  #
  # A Message is an item that is put on and taken off of the queues.
  # messages can be many things. In general, they are enough information in
  # from which to derive how to do a unit of work. Some might call it a Job or a
  # Task or such.
  #
  class Message
    # Create a message from a hash
    #
    # Generally a Message will be created soley by the QueueClassic system, they
    # are not normally created by the end user of this API. The vast majority of
    # all Message objects are what is returned from Consumer#reserve
    #
    def initialize( args )
      @data = args
    end

    # the unique identifier of this message
    def id
      @id ||= Integer(@data['id'])
    end

    # The payload the message carries
    def payload
      @data['payload']
    end

    # What time the message was put on the queue
    #
    def ready_at
      @ready_at ||= epoch_to_time( @data['ready_at'] )
    end

    # What time the message was reserved
    def reserved_at
      @reserved_at ||= epoch_to_time( @data['reserved_at'] )
    end

    # What worker reserved the message
    def reserved_by
      @data['reserved_by']
    end

    # What is the ip of the worker for this message
    def reserved_ip
      @data['reserved_ip'] || '127.0.0.1'
    end

    # What time was this message finalized
    def finalized_at
      if finalized? then
        return @finalized_at ||= epoch_to_time(@data['finzalized_at'])
      end
      nil
    end

    # What is the finalized note
    def finalized_note
      return @data['finalized_note'] if finalized?
      return nil
    end

    # Is this message finalized.
    def finalized?
      @data.has_key?('finalized_at')
    end

    #######
    private

    def epoch_to_time( t )
      sec, usec = t.split(".")
      return Time.at( sec.to_i, usec.to_i )
    end
  end
end
