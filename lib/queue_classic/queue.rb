module  QC
  class Queue
    def self.setup(args={})
      @@data = args[:data_store] || []
      self
    end

    def self.enqueue(job,params)
      @@data << {:job => job, :params => params}.to_json
    end

    def self.dequeue
      @@data.delete(@@data.first)
    end
  end
end
