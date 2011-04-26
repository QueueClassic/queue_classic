module QC
  module AbstractQueue

    def enqueue(job,*params)
      if job.respond_to?(:details) and job.respond_to?(:params)
        job = job.signature
        params = *job.params
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

module QC
  module ConnectionHelper

    def connection_status
      {:total => database.all_conns.count, :waiting => database.waiting_conns.count}
    end

    def disconnect
      database.disconnect
    end

  end
end

module  QC
  class Queue

    include AbstractQueue
    extend AbstractQueue

    include ConnectionHelper
    extend ConnectionHelper

    def self.array
      if defined? @@array
        @@array
      else
        @@database = Database.new
        @@array = DurableArray.new(@@database)
      end
    end

    def self.database
      @@database
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
