module QC
  class Worker

    def initialize
    end

    def run
      loop do
        job = QC.dequeue
        if job
          QC.work(job)
          QC.delete(job)
        else
          break
        end
      end
    end

  end
end
