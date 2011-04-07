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

    def database
      array.database
    end

    def array
      queue.data_store
    end

    def work(job)
      klass   = job.klass
      method  = job.method
      params  = job.params

      if params.class == Array
        klass.send(method,*params)
      else
        klass.send(method,params)
      end
    end

  end
end
