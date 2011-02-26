require 'singleton'

module  QC
  class Queue
    include Singleton
    def setup(args={})
      @data = args[:data_store]
    end

    def enqueue(job,params)
      @data << {"job" => job, "params" => params}
    end

    def dequeue
      @data.first
    end

    def query(signature)
      @data.search_details_column(signature)
    end

    def delete(job)
      @data.delete(job)
    end

    def delete_all
      @data.each {|j| delete(j) }
    end

    def length
      @data.count
    end
  end
end
