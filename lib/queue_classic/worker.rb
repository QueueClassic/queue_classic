module QC
  class Worker

    MAX_LOCK_ATTEMPTS = (ENV["QC_MAX_LOCK_ATTEMPTS"] || 5).to_i

    def initialize
      log("worker initialized")
      log("worker running exp. backoff algorith max_attempts=#{MAX_LOCK_ATTEMPTS}")
      @running = true

      @queue = QC::Queue.new(ENV["QUEUE"])
      log("worker table=#{@queue.database.table_name}")

      @fork_worker = ENV["QC_FORK_WORKER"] == "true"
      log("worker fork=#{@fork_worker}")

      handle_signals
    end

    def running?
      @running
    end

    def fork_worker?
      @fork_worker
    end

    def handle_signals
      %W(INT TERM).each do |sig|
        trap(sig) do
          if running?
            @running = false
            log("worker running=#{@running}")
          else
            raise Interrupt
          end
        end
      end
    end

    def start
      log("worker starting")
      while running?
        log("worker running...")
        if fork_worker?
          fork_and_work
        else
          work
        end
      end
    end

    def fork_and_work
      @cpid = fork { work }
      log("worker forked pid=#{@cpid}")
      Process.wait(@cpid)
    end

    def work
      log("worker start working")
      if job = lock_job
        log("worker locked job=#{job.id}")
        begin
          job.work
          log("worker finished job=#{job.id}")
        rescue Object => e
          log("worker failed job=#{job.id} exception=#{e.inspect}")
          handle_failure(job,e)
        ensure
          @queue.delete(job)
          log("worker deleted job=#{job.id}")
        end
      end
    end

    def lock_job
      log("worker attempting a lock")
      attempts = 0
      job = nil
      until job
        job = @queue.dequeue
        if job.nil?
          log("worker missed lock attempt=#{attempts}")
          attempts += 1
          if attempts < MAX_LOCK_ATTEMPTS
            seconds = 2**attempts
            log("worker sleeps seconds=#{seconds}")
            sleep(seconds)
            log("worker tries again")
            next
          else
            log("worker reached max attempts. max=#{MAX_LOCK_ATTEMPTS}")
            break
          end
        else
          log("worker successfully locked job")
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

    def log(msg)
      Logger.puts(msg)
    end

  end
end
