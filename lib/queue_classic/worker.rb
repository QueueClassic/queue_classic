module QC
  class Worker

    def start
      loop { work }
    end

    def work
      if job = QC.dequeue #blocks until we have a job
        begin
          QC.work(job)
        rescue Object => e
          handle_failure(job,e)
        ensure
          QC.delete(job)
        end
      end
    end

    #override this method to do whatever you want
    def handle_failure(job,e)
      puts "!"
      puts "! \t FAIL"
      puts "! \t \t #{job.inspect}"
      puts "! \t \t #{e.inspect}"
      puts "!"
    end

  end
end
