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
      @@data.b_head
    end

    def self.delete(job)
      @@data.delete(job)
    end

  end
end
