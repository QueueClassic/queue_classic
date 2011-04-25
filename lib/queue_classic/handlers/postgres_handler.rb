module QC
  class DurableArray

    def postgres_initialize(args={})
      @db_string  = args[:database]
      connection
      execute("SET client_min_messages TO 'warning'")
      with_log("setup PG LISTEN") { execute("LISTEN jobs") }
    end

    def <<(details)
      execute("INSERT INTO jobs (details) VALUES ('#{details.to_json}')")
      execute("NOTIFY jobs")
    end

    def count
      execute("SELECT COUNT(*) from jobs")[0]["count"].to_i
    end

    def delete(job)
      with_log("deleting job #{job.id}") { execute("DELETE FROM jobs WHERE id = #{job.id}") }
      job
    end

    def find(job)
      find_one {"SELECT * FROM jobs WHERE id = #{job.id}"}
    end

    def lock_head
      job = nil
      @connection.transaction do
        if job = find_one {"SELECT * FROM jobs WHERE locked_at IS NULL ORDER BY id ASC LIMIT 1 FOR UPDATE"}
          execute("UPDATE jobs SET locked_at = (CURRENT_TIMESTAMP) WHERE id = #{job.id} AND locked_at IS NULL")
        end
      end
      job
    end

    def first
      if job = lock_head
        job
      else
        @connection.wait_for_notify {|e,p,msg| job = lock_head if msg == "new-job" }
        job
      end
    end

    def each
      execute("SELECT * FROM jobs ORDER BY id ASC").each do |r|
        yield(JSON.parse(r["details"]))
      end
    end

    def execute(sql)
      @connection.async_exec(sql)
    end

    def find_one
      res = execute(yield)
      if res.count > 0
        res.map do |r|
          Job.new(
            "id"        => r["id"],
            "details"   => JSON.parse( r["details"]),
            "locked_at" => r["locked_at"]
          )
        end.pop
      end
    end

    def connection
      db_params = URI.parse(@db_string)
      if db_params.scheme == "postgres"
        @connection ||= PGconn.connect(
          :dbname   => db_params.path.gsub("/",""),
          :user     => db_params.user,
          :password => db_params.password,
          :host     => db_params.host
        )
      else
        @connection ||= PGconn.connect(:dbname => @db_string)
      end
    end

    def with_log(msg)
      res = yield
      if QC.logging_enabled?
        log(msg)
        log(res.cmd_status)           if res.respond_to?(:cmd_status)
        log(res.result_error_message) if res.respond_to?(:result_error_message)
      end
      res
    end

    def log(msg)
      puts "| \t" + msg
    end

  end
end

