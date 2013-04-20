module QC
  class Worker

    attr_reader :queue
    # In the case no arguments are passed to the initializer,
    # the defaults are pulled from the environment variables.
    def initialize(args={})
      @q_name           = args[:q_name]           ||= QC::QUEUE
      @top_bound        = args[:top_bound]        ||= QC::TOP_BOUND
      @fork_worker      = args[:fork_worker]      ||= QC::FORK_WORKER
      @listening_worker = args[:listening_worker] ||= QC::LISTENING_WORKER
      @max_attempts     = args[:max_attempts]     ||= QC::MAX_LOCK_ATTEMPTS

      @running = true
      @queue = Queue.new(@q_name, @listening_worker)
      log(args.merge(:at => "worker_initialized"))
    end

    # Start a loop and work jobs indefinitely.
    # Call this method to start the worker.
    # This is the easiest way to start working jobs.
    def start
      while @running
        @fork_worker ? fork_and_work : work
      end
    end

    # Call this method to stop the worker.
    # The worker may not stop immediately if the worker
    # is sleeping.
    def stop
      @running = false
    end

    # This method will tell the ruby process to FORK.
    # Define setup_child to hook into the forking process.
    # Using setup_child is good for re-establishing database connections.
    def fork_and_work
      @cpid = fork {setup_child; work}
      log(:at => :fork, :pid => @cpid)
      Process.wait(@cpid)
    end

    # This method will lock a job & process the job.
    def work
      if job = lock_job
        QC.log_yield(:at => "work", :job => job[:id]) do
          process(job)
        end
      end
    end

    # lock_job will attempt to lock a job in the queue's table. It uses an
    # exponential backoff in the event that a job was not locked. This method
    # will return a hash when a job is obtained.
    #
    # This method will terminate early if the stop method is called or
    # @max_attempts has been reached.
    #
    # It is important that callers delete the job when finished.
    # *@queue.delete(job[:id])*
    def lock_job
      log(:at => "lock_job")
      attempts = 0
      job = nil
      until !@running || job
        job = @queue.lock(@top_bound)
        if job.nil?
          log(:at => "failed_lock", :attempts => attempts)
          if attempts < @max_attempts
            wait(2**attempts)
            attempts += 1
            next
          else
            break
          end
        else
          log(:at => "finished_lock", :job => job[:id])
        end
      end
      job
    end

    # A job is processed by evaluating the target code.
    # Errors are delegated to the handle_failure method.
    # Also, this method will make the best attempt to delete the job
    # from the queue before returning.
    def process(job)
      begin
        call(job)
      rescue => e
        handle_failure(job, e)
      ensure
        @queue.delete(job[:id])
        log(:at => "delete_job", :job => job[:id])
      end
    end

    # Each job includes a method column. We will use ruby's eval
    # to grab the ruby object from memory. We send the method to
    # the object and pass the args.
    def call(job)
      args = job[:args]
      klass = eval(job[:method].split(".").first)
      message = job[:method].split(".").last
      klass.send(message, *args)
    end

    # If @listening_worker is set, the worker will use the database
    # to sleep. The database approach preferred over a syscall since
    # the database will break the sleep when new jobs are inserted into
    # the queue.
    def wait(t)
      if @listening_worker
        log(:at => "listen_wait", :wait => t)
        Conn.listen(@queue.chan)
        Conn.wait_for_notify(t)
        Conn.unlisten(@queue.chan)
        Conn.drain_notify
        log(:at => "finished_listening")
      else
        log(:at => "sleep_wait", :wait => t)
        Kernel.sleep(t)
      end
    end

    # This method will be called when an exception
    # is raised during the execution of the job.
    def handle_failure(job,e)
      log(:at => "handle_failure", :job => job, :error => e.inspect)
    end

    # This method should be overriden if
    # your worker is forking and you need to
    # re-establish database connections
    def setup_child
      log(:at => "setup_child")
    end

    def log(data)
      QC.log(data)
    end

  end
end
