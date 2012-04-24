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
      Conn.transaction do
        Conn.execute(File.read(CreateTable))
      end
    end

    def drop_table
      Conn.transaction do
        Conn.execute("DROP TABLE IF EXISTS queue_classic_jobs")
      end
    end

    def create_functions
      Conn.transaction do
        Conn.execute(File.read(SqlFunctions))
      end
    end

    def drop_functions
      Conn.transaction do
        Conn.execute(File.read(DropSqlFunctions))
      end
    end

  end
end
