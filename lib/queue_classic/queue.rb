module QC
  class Queue

    attr_reader :table, :top_bound

    def initialize(table, top_bound, notify=false)
      @table = table
      @chan = @table if notify
      @top_bound = top_bound
    end

    def enqueue(job,*params)
      if job.respond_to?(:signature) and job.respond_to?(:params)
        params = *job.params
        job = job.signature
      end
      json = OkJson.encode({"job" => job, "params" => params})
      Queries.insert(table, json, chan)
    end

    def dequeue
      Queries.first(table, top_bound)
    end

    def delete(job)
      Queries.delete(table, job.id)
    end

    def delete_all
      Queries.delete_all(table)
    end

    def length
      Queries.count(table)
    end

  end
end
