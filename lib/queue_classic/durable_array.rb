module QC
  class DurableArray

    def initialize(database)
      @database = database
      @table_name = @database.table_name
      @top_boundary = @database.top_boundary
    end

    def <<(details)
      execute("INSERT INTO #{@table_name} (details) VALUES ($1)", OkJson.encode(details))
      @database.notify if ENV["QC_LISTENING_WORKER"] == "true"
    end

    def count
      execute("SELECT COUNT(*) FROM #{@table_name}")[0]["count"].to_i
    end

    def delete(job)
      execute("DELETE FROM #{@table_name} WHERE id = $1;", job.id)
      job
    end

    def search_details_column(q)
      find_many { ["SELECT * FROM #{@table_name} WHERE details LIKE $1;", "%#{q}%"] }
    end

    def first
      find_one { ["SELECT * FROM lock_head($1, $2);", @table_name, @top_boundary] }
    end

    def each
      execute("SELECT * FROM #{@table_name} ORDER BY id ASC;").each do |r|
        yield Job.new(r)
      end
    end

    def find_one(&blk)
      find_many(&blk).pop
    end

    def find_many
      execute(*yield).map { |r| Job.new(r) }
    end

    def execute(sql, *params)
      @database.execute(sql, *params)
    end

  end
end
