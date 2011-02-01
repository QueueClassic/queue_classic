require 'uri'
require 'pg'

module QC
  class Job
    attr_accessor :id, :details, :locked_at
    def initialize(args={})
      @id        = args["id"]
      @details   = args["details"]
      @locked_at = args["locked_at"]
    end

    def klass
      Kernel.const_get(details["job"].split(".").first)
    end

    def method
      details["job"].split(".").last
    end

    def params
      params = details["params"]
      if params.length == 1
        return params[0]
      else
        params
      end
    end

  end

  class DurableArray
    def initialize(args={})
      @db_string  = args[:database]
      @connection = connection
      execute("SET client_min_messages TO 'warning'")
      with_log("setup PG LISTEN") { execute("LISTEN jobs") }
    end

    def <<(details)
      with_log("insert job into jobs table") do
        execute("INSERT INTO jobs (details) VALUES ('#{details.to_json}')")
      end
      with_log("send notification to jobs channel") do
        execute("NOTIFY jobs, 'new-job'")
      end
    end

    def count
      execute("SELECT COUNT(*) from jobs")[0]["count"].to_i
    end

    def delete(job)
      with_log("delete job") do
        execute("DELETE FROM jobs WHERE id = #{job.id}")
      end
      job
    end

    def find(job)
      find_one {"SELECT * FROM jobs WHERE id = #{job.id}"}
    end

    def head
      find_one {"SELECT * FROM jobs ORDER BY id ASC LIMIT 1"}
    end
    alias :first :head

    def lock_head
      job = nil
      with_log("start lock transaction") do
        @connection.transaction do
          log("inside transaction")
          if job = find_one {"SELECT * FROM jobs WHERE locked_at IS NULL ORDER BY id ASC LIMIT 1 FOR UPDATE"}
            with_log("lock acquired for #{job.inspect}") do
              locked  = execute("UPDATE jobs SET locked_at = (CURRENT_TIMESTAMP) WHERE id = #{job.id} AND locked_at IS NULL")
            end
          end
        end
      end
      job
    end

    def b_head
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
      if res.cmd_tuples > 0
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
      puts "|"
      puts "| \t" + msg
      puts "|"
    end

  end
end
