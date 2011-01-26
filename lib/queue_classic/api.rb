module QC
  module Api

    def enqueue(job,params)
      Queue.enqueue(job,params)
    end

    def dequeue(*args)
      Queue.dequeue(args)
    end

    def work(job)
      klass   = job.klass
      method  = job.method
      klass.send(method)
    end

  end
end
