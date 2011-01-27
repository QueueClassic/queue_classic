require 'pg'

module QC
  class Job
    attr_accessor :job_id, :details, :locked_at
    def initialize(args={})
      @job_id    = args["job_id"]
      @details   = args["details"]
      @locked_at = args["locked_at"]
    end
  end

  class DurableArray
    include Enumerable

    def initialize(args={})
      @connection = PGconn.connect(:dbname => "queue_classic_test")
      execute("SET client_min_messages TO 'warning'")
    end

    def <<(details)
      execute(
        "INSERT INTO jobs" +
        "(details)" +
        "VALUES ('#{details.to_json}')"
      )
    end

    def count
      execute("SELECT COUNT(*) from jobs")[0]["count"].to_i
    end

    def lock(job)
      execute("UPDATE jobs SET locked_at = (CURRENT_TIMESTAMP) WHERE job_id = #{job.job_id}")
    end

    def delete(job)
      execute("DELETE FROM jobs WHERE job_id = #{job.job_id}")
      job
    end

    def find(job)
      find_one { "SELECT * FROM jobs WHERE job_id= #{job.job_id}" }
    end

    def [](index)
      find_one { "SELECT * FROM jobs ORDER BY job_id ASC LIMIT 1 OFFSET #{index}" }
    end

    def head
      find_one { "SELECT * FROM jobs ORDER BY job_id ASC LIMIT 1" }
    end
    alias :first :head

    def tail
      find_one { "SELECT * FROM jobs ORDER BY job_id DESC LIMIT 1" }
    end
    alias :last :tail

    def each
      execute("SELECT * FROM jobs ORDER BY job_id ASC").each do |r|
        yield(JSON.parse(r["details"]))
      end
    end

    private

      def execute(sql)
        @connection.async_exec(sql)
      end

      def find_one
        res = execute(yield)
        if res.cmd_tuples > 0
          res.map do |r|
            Job.new(
              "job_id"    => r["job_id"],
              "details"   => JSON.parse( r["details"]),
              "locked_at" => r["locked_at"]
            )
          end.pop
        end
      end

      def quote(value)
        if value.kind_of?(String)
          "'#{value}'"
        elsif value.kind_of?(Numeric)
          value
        end
      end

  end
end
