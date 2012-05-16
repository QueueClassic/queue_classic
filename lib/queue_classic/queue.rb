module QC
  class Queue

    attr_reader :name, :chan

    def initialize(name, notify=false)
      @name = name
      @chan = @name if notify
    end

    def enqueue_with_priority(priority, method, *args)
      Queries.insert(name, method, args, chan, priority)
    end

    def enqueue(method, *args)
      Queries.insert(name, method, args, chan, 1)
    end

    def lock(top_bound=TOP_BOUND)
      Queries.lock_head(name, top_bound)
    end

    def delete(id)
      Queries.delete(id)
    end

    def delete_all
      Queries.delete_all(@name)
    end

    def count
      Queries.count(@name)
    end

  end
end
