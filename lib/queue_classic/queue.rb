module  QC
  class Queue
    def self.setup(args={})
      @@data = args[:data_store] || []
      self
    end

    def self.enqueue(job)
      @@data << job
    end

    def self.dequeue
      @@data.delete(@@data.first)
    end
  end
end
