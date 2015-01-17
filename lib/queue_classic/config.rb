module QC
  module Config
    # You can use the APP_NAME to query for
    # postgres related process information in the
    # pg_stat_activity table.
    def app_name
      ENV["QC_APP_NAME"] || "queue_classic"
    end

    # Number of seconds to block on the listen chanel for new jobs.
    def wait_time
      (ENV["QC_LISTEN_TIME"] || 5).to_i
    end

    # Why do you want to change the table name?
    # Just deal with the default OK?
    # If you do want to change this, you will
    # need to update the PL/pgSQL lock_head() function.
    # Come on. Don't do it.... Just stick with the default.
    def table_name
      "queue_classic_jobs"
    end

    # Each row in the table will have a column that
    # notes the queue. You can point your workers
    # at different queues but only one at a time.
    def queue
      ENV["QUEUE"] || "default"
    end

    def queues
      (ENV["QUEUES"] && ENV["QUEUES"].split(",").map(&:strip)) || []
    end

    # Set this to 1 for strict FIFO.
    # There is nothing special about 9....
    def top_bound
      (ENV["QC_TOP_BOUND"] || 9).to_i
    end

    # Set this variable if you wish for
    # the worker to fork a UNIX process for
    # each locked job. Remember to re-establish
    # any database connections. See the worker
    # for more details.
    def fork_worker?
      !ENV["QC_FORK_WORKER"].nil?
    end
  end
end
