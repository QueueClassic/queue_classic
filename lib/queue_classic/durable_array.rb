module QC
  class DurableArray

    def initialize(database)
      @database = database
      @table_name = @database.table_name
    end

    def <<(details)
      execute("INSERT INTO #{@table_name} (details) VALUES ('#{JSON.dump(details)}')")
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

    def first
      find_one { "SELECT * FROM lock_head('#{@table_name}')" }
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
