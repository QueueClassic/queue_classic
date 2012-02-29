module QC
  module AbstractQueue

    def enqueue(job,*params)
      if job.respond_to?(:signature) and job.respond_to?(:params)
        params = *job.params
        job = job.signature
      end
      array << {"job" => job, "params" => params}
    end

    def dequeue
      array.first
    end

    def query(signature)
      array.search_details_column(signature)
    end

    def delete(job)
      array.delete(job)
    end

    def delete_all
      array.each {|j| delete(j) }
    end

    def length
      array.count
    end

  end
end

module  QC
  class Queue

    include AbstractQueue
    extend AbstractQueue

    def self.array
      default_queue.array
    end

    def self.database
      default_queue.database
    end

    def self.default_queue
      @queue ||= new(nil)
    end

    def initialize(queue_name)
      @database = Database.new(queue_name)
      @array = DurableArray.new(@database)
    end

    def array
      @array
    end

    def database
      @database
    end

  end
end
