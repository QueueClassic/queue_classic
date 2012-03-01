module QC
  class Queue

    attr_reader :table, :top_bound, :chan

    def initialize(table, top_bound, notify=false)
      @table = table
      @chan = @table if notify
      @top_bound = top_bound
    end

    def enqueue(method, *args)
      Queries.insert(table, method, args, chan)
    end

    def lock
      Queries.lock_head(table, top_bound)
    end

    def delete(id)
      Queries.delete(table, id)
    end

    def delete_all
      Queries.delete_all(table)
    end

    def count
      Queries.count(table)
    end

  end
end
