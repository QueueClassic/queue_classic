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
      @db_conn  = PGconn.open(:dbname => args[:dbname])
      execute("SET client_min_messages TO 'warning'")
    end

    def <<(details)
      new_job = Job.new("details"=>details)
      execute(
        "INSERT INTO jobs" +
        "(details)" +
        "VALUES (#{quote(new_job.details)})"
      )
    end

    def first
      head
    end

    def last
      tail
    end

    def delete(job)
      res = execute(
        "DELETE FROM jobs WHERE job_id = #{job.job_id}"
      )
    end

    def find(job)
      res = execute(
        "SELECT * FROM jobs WHERE job_id= #{job.job_id}"
      )
      get_one(res)
    end

    def [](index)
      res = execute(
        "SELECT * FROM jobs ORDER BY job_id ASC LIMIT 1 OFFSET #{index}"
      )
      get_one(res)
    end

    def head
      res = execute(
        "SELECT * FROM jobs ORDER BY job_id ASC LIMIT 1"
      )
      get_one(res)
    end

    def tail
      res = execute(
        "SELECT * FROM jobs ORDER BY job_id DESC LIMIT 1"
      )
      get_one(res)
    end

    def each
      execute(
        "SELECT * FROM jobs ORDER BY job_id ASC"
      ).each {|r| yield(r["details"]) }
    end

    private

      def execute(sql)
        @db_conn.async_exec(sql)
      end

      def get_one(res)
        if res.cmd_tuples > 0
          res.map {|r| Job.new(r)}.pop
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
