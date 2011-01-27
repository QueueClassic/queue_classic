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
      @@data.lock(next_in_queue)
      next_in_queue
    end
  end
end
