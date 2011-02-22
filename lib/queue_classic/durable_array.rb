module QC
  class DurableArray

    def initialize(args={})
      @db_string  = args[:database]
    end

    def <<(details)
      execute("INSERT INTO jobs (details) VALUES ('#{details.to_json}')")
      execute("NOTIFY jobs, 'new-job'")
    end

    def count
      execute("SELECT COUNT(*) from jobs")[0]["count"].to_i
    end

    def delete(job)
      execute("DELETE FROM jobs WHERE id = #{job.id}")
      job
    end

    def find(job)
      find_one {"SELECT * FROM jobs WHERE id = #{job.id}"}
    end

    def lock_head
      job = nil
      connection.transaction do
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
        execute("LISTEN jobs")
        connection.wait_for_notify {|e,p,msg| job = lock_head if msg == "new-job" }
        job
      end
    end

    def each
      execute("SELECT * FROM jobs ORDER BY id ASC").each do |r|
        yield Job.new(r)
      end
    end

    def execute(sql)
      connection.exec(sql)
    end

    def find_one
      res = execute(yield)
      if res.count > 0
        res.map {|r| Job.new(r)}.pop
      end
    end

    def connection
      db_params = URI.parse(@db_string)
      @connection ||= if db_params.scheme == "postgres"
        PGconn.connect(
          :dbname   => db_params.path.gsub("/",""),
          :user     => db_params.user,
          :password => db_params.password,
          :host     => db_params.host
        )
      else
        PGconn.connect(:dbname => @db_string)
      end
    end

  end
end
