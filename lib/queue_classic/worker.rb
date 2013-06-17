module QC
  class Worker

    attr_accessor :queue, :running
    # In the case no arguments are passed to the initializer,
    # the defaults are pulled from the environment variables.
    def initialize(queue=nil)
      @queue = queue || QC.default_queue
      log(:at => "worker_initialized")
    end

    # Start a loop and work jobs indefinitely.
    # Call this method to start the worker.
    # This is the easiest way to start working jobs.
    def start
      @running = true
      work while @running
    end

    # Call this method to stop the worker.
    # The worker may not stop immediately if the worker
    # is sleeping.
    def stop
      @running = false
    end

    # This method will lock a job & process the job.
    def work(top_bound=TOP_BOUND)
      if job = lock_job(top_bound)
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
    def lock_job(top_bound)
      log(:at => "lock_job")
      while @running
        if job = @queue.lock(top_bound)
          log(:at => "finished_lock", :job => job[:id])
          return job
        else
          Conn.wait(@queue.name)
        end
      end
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
