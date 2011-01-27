module  QC
  class Queue
    def self.setup(args={})
      @@data = args[:data_store] || []
      self
    end

    def self.enqueue(job,params)
      @@data << {"job" => job, "params" => params}
    end

    def self.dequeue
      next_in_queue = @@data.first
      if next_in_queue
        @@data.lock(next_in_queue)
        next_in_queue
      end
    end

    def self.delete(job)
      @@data.delete(job)
    end

  end
end
