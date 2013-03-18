module QC
  class Queue

    attr_reader :name
    def initialize(name)
      @name = name
    end

    def enqueue(method, *args)
      Queries.insert(name, method, args)
    end

    def lock(top_bound=TOP_BOUND)
      Queries.lock_head(name, top_bound)
    end

    def delete(id)
      Queries.delete(id)
    end

    def delete_all
      Queries.delete_all(name)
    end

    def count
      Queries.count(name)
    end

  end
end
