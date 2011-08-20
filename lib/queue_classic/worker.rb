module QC
  class Worker

    FORK_WORKER = ENV["QC_FORK_WORKER"] == "true"
    MAX_LOCK_ATTEMPTS = (ENV["QC_MAX_LOCK_ATTEMPTS"] || 5).to_i

    def initialize
      @running = true
      @queue = QC::Queue.new(ENV["QUEUE"])
      @fork = FORK_WORKER
      handle_signals
    end

    def running?
      @running == true
    end

    def can_fork?
      @fork == true
    end

    def handle_signals
      %W(INT TERM).each do |sig|
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
      while running?
        if can_fork?
          fork_and_work
        else
          work
        end
      end
    end

    def fork_and_work
      @cpid = fork { work }
      Process.wait(@cpid)
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
      job = nil
      until job
        if job = @queue.dequeue
          @queue.database.unlisten
        else
          @queue.database.listen
          @queue.database.wait_for_notify
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
