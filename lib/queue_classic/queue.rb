require 'singleton'

module  QC
  class Queue
    include Singleton

    attr_reader :data_store
    def setup(args={})
      @data_store = args[:data_store]
    end

    def enqueue(job,params)
      @data_store << {"job" => job, "params" => params}
    end

    def dequeue
      @data_store.first
    end

    def query(signature)
      @data_store.search_details_column(signature)
    end

    def delete(job)
      @data_store.delete(job)
    end

    def delete_all
      @data_store.each {|j| delete(j) }
    end

    def length
      @data_store.count
    end
  end
end
