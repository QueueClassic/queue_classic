module QC
  class DurableArray

    def initialize(database_url)
      @database_url = database_url
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

    def search_details_column(q)
      find_many { "SELECT * FROM jobs WHERE details LIKE '%#{q}%'" }
    end

    def lock_head
      find_one { "SELECT * FROM lock_head() LIMIT 1" }
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

    def find_one(&blk)
      find_many(&blk).pop
    end

    def find_many
      execute(yield).map {|r| Job.new(r)}
    end

    def connection
      db_params = URI.parse(@database_url)
      @connection ||= PGconn.connect(
        :dbname   => db_params.path.gsub("/",""),
        :user     => db_params.user,
        :password => db_params.password,
        :host     => db_params.host
      )
    end

  end
end
