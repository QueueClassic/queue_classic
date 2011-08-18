module QC
  class Worker
    MAX_LOCK_ATTEMPTS = (ENV["QC_MAX_LOCK_ATTEMPTS"] || 5).to_i

    def initialize
      @running = true
      @queue = QC::Queue.new(ENV["QUEUE"])
      handle_signals
    end

    def running?
      @running
    end

    def handle_signals
      %W(INT TRAP).each do |sig|
        trap(sig) do
          if running?
            @running = false
          else
            raise Interrupt
          end
        end
      end
    end

    def start
      work while running?
    end

    def work
      if job = lock_job
        begin
          job.work
        rescue Object => e
          handle_failure(job,e)
        ensure
          @queue.delete(job)
        end
      end
    end

    def lock_job
      attempts = 0
      job = nil
      until job
        job = @queue.dequeue
        if job.nil?
          attempts += 1
          if tries < MAX_LOCK_ATTEMPTS
            sleep(2**attempts)
            next
          end
        else
        end
      end
      job
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
