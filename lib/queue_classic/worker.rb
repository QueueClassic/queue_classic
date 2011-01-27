module QC
  module Worker
    def run
      loop do
        job = QC.dequeue
        if job
          QC.work(job)
        end
      end
    end
  end
end
