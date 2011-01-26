module  QC
  class Queue
    def self.setup(args={})
      data_store = args[:data_store]
      raise ArgumentError unless data_store.respond_to?(:<<)
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
