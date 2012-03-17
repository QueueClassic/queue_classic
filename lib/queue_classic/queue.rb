module QC
  class Queue

    attr_reader :name, :chan

    def initialize(name, notify=false)
      @name = name
      @chan = @name if notify
    end

    def enqueue(method, *args)
      Queries.insert(name, method, args, chan)
    end

    def lock(top_bound=TOP_BOUND)
      Queries.lock_head(name, top_bound)
    end

    def delete(id)
      Queries.delete(id)
    end

    def delete_all(q_name=nil)
      Queries.delete_all(q_name)
    end

    def count(q_name=nil)
      Queries.count(q_name)
    end

  end
end
