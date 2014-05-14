require_relative 'queue'
require_relative 'conn_adapter'

module QC
  # A Worker object can process jobs from one or many queues.
  class Worker

    attr_accessor :queues, :running

    # Creates a new worker but does not start the worker. See Worker#start.
    # This method takes a single hash argument. The following keys are read:
    # fork_worker:: Worker forks each job execution.
    # wait_interval:: Time to wait between failed lock attempts
    # connection:: PGConn object.
    # q_name:: Name of a single queue to process.
    # q_names:: Names of queues to process. Will process left to right.
    # top_bound:: Offset to the head of the queue. 1 == strict FIFO.
    def initialize(args={})
      @fork_worker = args[:fork_worker] || QC::FORK_WORKER
      @wait_interval = args[:wait_interval] || QC::WAIT_TIME

      if args[:connection]
        @conn_adapter = ConnAdapter.new(args[:connection])
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
    def work
      queue, job = lock_job
      if queue && job
        QC.log_yield(:at => "work", :job => job[:id]) do
          process(queue, job)
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
    def process(queue, job)
      start = Time.now
      finished = false
      begin
        result = @fork_worker ? call_forked(job) : call(job)
        result.tap do
          queue.delete(job[:id])
          finished = true
        end
      rescue => e
        handle_failure(job, e)
        finished = true
      ensure
        if !finished
          queue.unlock(job[:id])
        end
        ttp = Integer((Time.now - start) * 1000)
        QC.measure("time-to-process=#{ttp} source=#{queue.name}")
      end
    end

    # Each job includes a method column. We will use ruby's eval
    # to grab the ruby object from memory. We send the method to
    # the object and pass the args.
    def call(job)
      args = job[:args]
      receiver_str, _, message = job[:method].rpartition('.')
      receiver = eval(receiver_str)
      receiver.send(message, *args)
    end

    # Invoke worker inside a forked process. Worker should NOT
    # use shared pg connection, as it corrupts it. It pipes the 
    # result back via IO.pipe, passes exceptions through.
    # To use pg inside worker, use connection pool or a fresh connection
    def call_forked(job)
      read, write = IO.pipe
      prepare_child
      cpid = fork do
        read.close
        setup_child
        begin
          result = call(job)
        rescue => e
          result = e
        ensure
          Marshal.dump(result, write)
          # Exit forked process without running exit handlers 
          # so pg connection is not corrupted
          exit!(0) 
        end
      end
      log(:at => :fork, :pid => cpid)
      write.close
      result = read.read
      Process.wait(cpid)
      loaded = Marshal.load(result)
      raise loaded if Exception === loaded
      loaded
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
