module QC
  # Represents a job being executed
  class Job

    attr_accessor :id, :queue, :method_name, :args, :scheduled_at

    def initialize(id, queue, method_name, args)
      @id = id
      @queue = queue
      @method_name = method_name
      @args = args
    end

    def to_s
      {:id => id, :q_name => queue.name, :method_name => method_name, :args => args, :scheduled_at => scheduled_at}.to_s
    end

  end

end