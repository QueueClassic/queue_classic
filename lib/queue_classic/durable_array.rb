require 'pg'

module QC
  class Job
    attr_accessor :job_id, :details
    def initialize(args={})
      @job_id   = args["job_id"]
      @details  = args["details"]
    end
  end

  class DurableArray
    include Enumerable

    def initialize(args={})
      @connection = PGconn.connect(:dbname => args[:dbname])
      execute("SET client_min_messages TO 'warning'")
    end

    def <<(details)
      execute(
        "INSERT INTO jobs" +
        "(details)" +
        "VALUES ('#{details.to_json}')"
      )
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
      execute(
        "SELECT * FROM jobs ORDER BY job_id ASC"
      ).each {|r| yield(JSON.parse(r["details"])) }
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
              "job_id" => r["job_id"],
              "details"=> JSON.parse( r["details"] )
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
