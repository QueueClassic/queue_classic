module QC
  module Api

    def enqueue(job,params={})
      Queue.enqueue(job,params)
    end

    def dequeue
      Queue.dequeue
    end

    def delete(job)
      Queue.delete(job)
    end

    def work(job)
      klass   = job.klass
      method  = job.method
      klass.send(method)
    end

  end
end
