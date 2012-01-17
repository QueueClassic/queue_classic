module QueueClassic
  # Representing everything about a single job.
  #
  # This generally maps to a row in the jobs table in the database.
  #
  # There is a specific field 'details' that is in the args, and this is to be
  # a JSON parsable string.
  #
  # In order for the 'params', 'signature', 'method' and 'klass' methods of Job
  # to work, the JSON should have at a minimum the following format:
  #
  #   {
  #     'job' => Class.method,
  #     'params' => [ p1, p2, p3 ]
  #   }
  #
  class Job
    def initialize( args = {} )
      @data = Hash.new
      args.each_pair do |k,v|
        @data[k] = v
      end
    end

    # The job ID, this is assigned when the job is submitted to the database
    #
    def id
      @id ||= Integer(@data['id'])
    end

    # The details of the job, it is assumed that this is JSON
    def details
      @details ||= JSON.parse( @data['details'] )
    end

    # The Class.method signature as derived from the JSON 'details' field
    #
    def signature
      details['job']
    end

    # The Class from the derived field from the JSON 'details' field
    #
    def klass
      eval(signature.split('.').first)
    end

    # The method of the class from the JSON 'details' field
    #
    def method
      signature.split('.').last
    end

    # The value in the 'params' field of the parsed JSOn from 'details'
    #
    def params
      p = details['params']
      return [] if p.nil?
      if p.length > 1 then
        return p
      else
        return p.first
      end
    end

    # What queue the job is/was on
    def queue
      @data['queue']
    end

    # What time the job was enqueued
    #
    def ready_at
      @ready_at ||= Time.parse( @data['ready_at'] )
    end

    # What time the job was reserved
    def reserved_at
      @reserved_at ||= Time.pase( @data['reserved_at'] )
    end

    # What worker reserved the job
    def reserved_by
      @data['reserved_by']
    end

    # What time the job was finished
    def finalized_at
      @finalized_at ||= Time.parse( @data['finalized_at'] )
    end

    # Any message to put into the finalized job
    def finalized_message
      @data['finalized_message']
    end

    # look at t
  end
end
