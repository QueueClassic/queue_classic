module QC
  class Worker

    def initialize(q_name, top_bound, fork_worker, listening_worker, max_attempts)
      log("worker initialized")
      @running = true

      @queue = Queue.new(q_name, listening_worker)
      log("worker queue=#{@queue.name}")

      @top_bound = top_bound
      log("worker top_bound=#{@top_bound}")

      @fork_worker = fork_worker
      log("worker fork=#{@fork_worker}")

      @listening_worker = listening_worker
      log("worker listen=#{@listening_worker}")

      @max_attempts = max_attempts
      log("max lock attempts =#{@max_attempts}")

      handle_signals
    end

    def running?
      @running
    end

    def fork_worker?
      @fork_worker
    end

    def can_listen?
      @listening_worker
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

    # This method should be overriden if
    # your worker is forking and you need to
    # re-establish database connectoins
    def setup_child
      log("forked worker running setup")
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
      @cpid = fork { setup_child; work }
      log("worker forked pid=#{@cpid}")
      Process.wait(@cpid)
    end

    def work
      log("worker start working")
      if job = lock_job
        log("worker locked job=#{job[:id]}")
        begin
          call(job).tap do
            log("worker finished job=#{job[:id]}")
          end
        rescue Object => e
          log("worker failed job=#{job[:id]} exception=#{e.inspect}")
          handle_failure(job, e)
        ensure
          @queue.delete(job[:id])
          log("worker deleted job=#{job[:id]}")
        end
      end
    end

    def lock_job
      log("worker attempting a lock")
      attempts = 0
      job = nil
      until job
        job = @queue.lock(@top_bound)
        if job.nil?
          log("worker missed lock attempt=#{attempts}")
          attempts += 1
          if attempts < @max_attempts
            seconds = 2**attempts
            wait(seconds)
            log("worker tries again")
            next
          else
            log("worker reached max attempts. max=#{@max_attempts}")
            break
          end
        else
          log("worker successfully locked job")
        end
      end
      job
    end

    def call(job)
      args = job[:args]
      klass = eval(job[:method].split(".").first)
      message = job[:method].split(".").last
      klass.send(message, *args)
    end

    def wait(t)
      if can_listen?
        log("worker waiting on LISTEN")
        Conn.listen(@queue.chan)
        Conn.wait_for_notify(t)
        Conn.unlisten(@queue.chan)
        Conn.drain_notify
        log("worker finished LISTEN")
      else
        log("worker sleeps seconds=#{t}")
        Kernel.sleep(t)
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

    def log(msg)
      Log.info(msg)
    end

  end
end
