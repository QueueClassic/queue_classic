module QC
  module Setup
    extend self

    def create
      create_table
      create_functions
    end

    def drop
      drop_functions
      drop_table
    end

    def create_table
      Conn.execute(File.read(CreateTable))
    end

    def drop_table
      Conn.execute("DROP TABLE IF EXISTS queue_classic_jobs")
    end

    def create_functions
      Conn.execute(File.read(SqlFunctions))
    end

    def drop_functions
      Conn.execute(File.read(DropSqlFunctions))
    end

  end
end
