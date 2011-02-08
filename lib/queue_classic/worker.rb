module QC
  class Worker

    def initialize
      @worker_id = rand(1000)
    end

    def start
      loop { work }
    end

    def work
      job = QC.dequeue
      # if we are here, dequeue has unblocked
      # and we may have a job.
      if job
        QC.work(job)
      end

    end

  end
end
