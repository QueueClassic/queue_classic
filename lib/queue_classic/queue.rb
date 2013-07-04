module QC
  class Queue

    attr_reader :name, :top_bound
    def initialize(name, top_bound=nil)
      @name = name
      @top_bound = top_bound || QC::TOP_BOUND
    end

    def enqueue(method, *args)
      Queries.insert(name, method, args)
    end

    def lock
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
