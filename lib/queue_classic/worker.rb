module QC
  class Worker
    def start
      worker_id = rand(1000)
      puts "#{worker_id} ready for work"
      loop do
        job = QC.dequeue
        # if we are here, dequeue has unblocked
        # and we may have a job.
        if job
          puts "#{worker_id} working job"
          QC.work(job)
        end
      end
    end
  end
end
