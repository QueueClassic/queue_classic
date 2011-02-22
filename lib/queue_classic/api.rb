module QC
  module Api

    def queue
      @queue ||= Queue.instance
    end

    def enqueue(job,*params)
      if job.respond_to?(:details) and job.respond_to?(:params)
        queue.enqueue(job.signature, (job.params || []))
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

    def queue_length
      queue.length
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

    def logging_enabled?
      ENV["LOGGING"]
    end

  end
end
