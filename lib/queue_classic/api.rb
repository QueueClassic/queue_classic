module QC
  module Api

    def queue
      @queue ||= Queue.instance
    end

    def enqueue(job,*params)
      queue.enqueue(job,params)
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

      klass.send(method,params)
    end

    def logging_enabled?
      ENV["LOGGING"]
    end

  end
end
