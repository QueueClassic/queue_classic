require_relative 'queue'
require_relative 'conn_adapter'

module QC
  # A Worker object can process jobs from one or many queues.
  class Worker

    attr_accessor :queues, :running

    # Creates a new worker but does not start the worker. See Worker#start.
    # This method takes a single hash argument. The following keys are read:
    # fork_worker:: Worker forks each job execution.
    # asynchronous:: When true, the parent process doesnt wait for forks
    # wait_interval:: Time to wait between failed lock attempts
    # connection:: PGConn object.
    # q_name:: Name of a single queue to process.
    # q_names:: Names of queues to process. Will process left to right.
    # top_bound:: Offset to the head of the queue. 1 == strict FIFO.
    def initialize(args={})
      @fork_worker = args[:fork_worker] || QC::FORK_WORKER
      @wait_interval = args[:wait_interval] || QC::WAIT_TIME
      @asynchronous = args[:asynchronous] || QC::ASYNCHRONOUS_WORKER

      if args[:connection]
        @conn_adapter = ConnAdapter.new(args[:connection])
      elsif @asynchronous
        @conn_adapter = QC.default_conn_adapter
      elsif QC.has_connection?
        @conn_adapter = QC.default_conn_adapter
      end

      @queues = setup_queues(@conn_adapter,
        (args[:q_name] || QC::QUEUE),
        (args[:q_names] || QC::QUEUES),
        (args[:top_bound] || QC::TOP_BOUND))
      log(args.merge(:at => "worker_initialized"))
      @running = true
    end

    # Commences the working of jobs.
    # start() spins on @running –which is initialized as true.
    # This method is the primary entry point to starting the worker.
    # The canonical example of starting a worker is as follows:
    # QC::Worker.new.start
    def start
      unlock_jobs_of_dead_workers()
      while @running
        work
      end
    end

    # Signals the worker to stop taking new work.
    # This method has no immediate effect. However, there are
    # two loops in the worker (one in #start and another in #lock_job)
    # which check the @running variable to determine if further progress
    # is desirable. In the case that @running is false, the aforementioned
    # methods will short circuit and cause the blocking call to #start
    # to unblock.
    def stop
      @running = false
    end

    # Blocks on locking a job, and once a job is locked,
    # it will process the job.
    def work(&block)
      queue, job = lock_job
      if queue && job
        QC.log_yield(:at => "work", :job => job[:id]) do
          process(queue, job, &block)
        end
      end
    end

    # Attempt to lock a job in the queue's table.
    # If a job can be locked, this method returns an array with
    # 2 elements. The first element is the queue from which the job was locked
    # and the second is a hash representation of the job.
    # If a job is returned, its locked_at column has been set in the
    # job's row. It is the caller's responsibility to delete the job row
    # from the table when the job is complete.
    def lock_job
      log(:at => "lock_job")
      job = nil
      while @running
        @queues.each do |queue|
          if job = queue.lock
            return [queue, job]
          end
        end
        @conn_adapter.wait(@wait_interval, *@queues.map {|q| q.name})
      end
    end

    # This will unlock all jobs any postgres' PID that is not existing anymore
    # to prevent any infinitely locked jobs
    def unlock_jobs_of_dead_workers
      @conn_adapter.execute("UPDATE #{QC::TABLE_NAME} SET locked_at = NULL, locked_by = NULL WHERE locked_by NOT IN (SELECT pid FROM pg_stat_activity);")
    end

    # A job is processed by evaluating the target code.
    # if the job is evaluated with no exceptions
    # then it is deleted from the queue.
    # If the job has raised an exception the responsibility of what
    # to do with the job is delegated to Worker#handle_failure.
    # If the job is not finished and an INT signal is traped,
    # this method will unlock the job in the queue.
    def process(queue, job, &callback)
      start = Time.now
      call(job, callback) do |result|
        log_result(queue, job, result, start)
      end
    end

    # If a result is not Exception, the job is considered a success
    def log_result(queue, job, result, start)
      ttp = Integer((Time.now - start) * 1000)
      QC.measure("time-to-process=#{ttp} source=#{queue.name}")
      if @asynchronous && queue.conn_adapter.needs_its_own_connection?
        queue.conn_adapter.reestablish
      end
      if (Exception === result)
        log_failure(queue, job, result)
      else
        log_success(queue, job, result)
      end
      result
    end

    def log_failure(queue, job, result)
      queue.unlock(job[:id])
      handle_failure(job, result)
    end

    def log_success(queue, job, result)
      queue.delete(job[:id])
    end

    # Call the job, fork the process if needed
    def call(job, callback = nil, &block)
      if @fork_worker
        call_forked(job, callback, &block)
      else
        call_inline(job, callback, &block)
      end
    end

    # Call the job within current process, handle exceptions
    def call_inline(job, callback = nil, &block)
      result = call_worker(job)
    rescue => e
      result = e
    ensure
      call_ensure(result, callback, &block)
    end

    # Call returning block and user callback in worker process
    def call_ensure(result, callback = nil)
      callback.call(result) if callback
      yield(result) if block_given?
      result
    end

    # Each job includes a method column. We will use ruby's eval
    # to grab the ruby object from memory. We send the method to
    # the object and pass the args.
    def call_worker(job)
      args = job[:args]
      receiver_str, _, message = job[:method].rpartition('.')
      receiver = eval(receiver_str)
      receiver.send(message, *args)
    end

    # Invoke worker inside a forked process. Worker should NOT
    # use shared pg connection, as it corrupts it. Worker clones
    # connection for you behind the scenes if you try to execute
    # anything in conn_adapter. The forked process pipes the result 
    # back via IO.pipe and re-raises exceptions. If a worker is
    # asynchronous, it returns pid as output and logs completion on
    # its own.
    def call_forked(job, callback = nil, &block)
      read, write = IO.pipe
      prepare_child
      fork_pid = fork do
        setup_child
        result = call_inline(job, callback, &block)
        unless @asynchronous
          read.close
          Marshal.dump(result, write)
        end
        # Exit forked process without running exit handlers 
        # so pg connection in parent process doesnt break
        exit!(0) 
      end
      log(:at => :fork, :pid => fork_pid)
      unless @asynchronous
        write.close
        marshalled = read.read
        Process.wait(fork_pid)
        yield Marshal.load(marshalled)
      else
        fork_pid
      end
    end

    # This method will be called when an exception
    # is raised during the execution of the job.
    def handle_failure(job,e)
      $stderr.puts("count#qc.job-error=1 job=#{job} error=#{e.inspect}")
    end

    # This method should be overriden if
    # your worker is forking and you need to
    # re-establish database connections
    def setup_child
    end

    # This method is called before process is forked
    # We avoid using pg inside a forked process,
    # so logging has to happen her
    def prepare_child
      log(:at => "setup_child")
    end

    def log(data)
      QC.log(data)
    end

    private

    def setup_queues(adapter, queue, queues, top_bound)
      names = queues.length > 0 ? queues : [queue]
      names.map do |name|
        QC::Queue.new(name, top_bound).tap do |q|
          q.conn_adapter = adapter
        end
      end
    end

  end
end
