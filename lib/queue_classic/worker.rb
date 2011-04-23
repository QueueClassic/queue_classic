module QC
  class Worker

    def initialize
      @running = true
      handle_signals
    end

    def handle_signals
      %W( INT TRAP).each do |sig|
        trap(sig) do
          if running?
            @running = false
          else
            raise Interrupt
          end
        end
      end
    end

    def running?
      @running
    end

    def start
      while running? do
        work
      end
    end

    def work
      if job = QC.dequeue #blocks until we have a job
        begin
          job.work
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
