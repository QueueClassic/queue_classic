module QC
  module Api

    def queue
      @queue ||= Queue.instance
    end

    def enqueue(job,*params)
      if job.respond_to?(:details) and job.respond_to?(:params)
        p = *job.params
        queue.enqueue(job.signature, p)
      else
        queue.enqueue(job,params)
      end
    end

    def dequeue
      queue.dequeue
    end

    def delete(job)
      queue.delete(job)
    end

    def delete_all
      queue.delete_all
    end

    def query(q)
      queue.query(q)
    end

    def queue_length
      queue.length
    end

    def connection_status
      {:total => database.all_conns.count, :waiting => database.waiting_conns.count}
    end

    def database
      array.database
    end

    def array
      queue.data_store
    end

  end
end
