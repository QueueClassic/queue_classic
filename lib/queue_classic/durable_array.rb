module QC
  class DurableArray

    def initialize(database)
      @database = database
      @table_name = @database.table_name
    end

    def <<(details)
      execute("INSERT INTO #{@table_name} (details) VALUES ('#{details.to_json}')")
      execute("NOTIFY queue_classic_jobs, 'new-job'")
    end

    def count
      execute("SELECT COUNT(*) FROM #{@table_name}")[0]["count"].to_i
    end

    def delete(job)
      execute("DELETE FROM #{@table_name} WHERE id = #{job.id}")
      job
    end

    def find(job)
      find_one {"SELECT * FROM #{@table_name} WHERE id = #{job.id}"}
    end

    def search_details_column(q)
      find_many { "SELECT * FROM #{@table_name} WHERE details LIKE '%#{q}%'" }
    end

    def lock_head
      find_one { "SELECT * FROM lock_head('#{@table_name}')" }
    end

    def first
      if job = lock_head
        job
      else
        @database.connection.wait_for_notify(1) {|e,p,msg| job = lock_head if msg == "new-job" }
        job
      end
    end

    def each
      execute("SELECT * FROM #{@table_name} ORDER BY id ASC").each do |r|
        yield Job.new(r)
      end
    end

    def find_one(&blk)
      find_many(&blk).pop
    end

    def find_many
      execute(yield).map {|r| Job.new(r)}
    end

    def execute(sql)
      @database.execute(sql)
    end

  end
end
