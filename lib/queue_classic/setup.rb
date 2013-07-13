module QC
  module Setup
    Root = File.expand_path("../..", File.dirname(__FILE__))
    SqlFunctions = File.join(Root, "/sql/ddl.sql")
    CreateTable = File.join(Root, "/sql/create_table.sql")
    DropSqlFunctions = File.join(Root, "/sql/drop_ddl.sql")

    def self.create(pool)
      pool.use do |c|
        c.execute(File.read(CreateTable))
        c.execute(File.read(SqlFunctions))
      end
    end

    def self.drop(pool)
      pool.use do |c|
        c.execute("DROP TABLE IF EXISTS queue_classic_jobs CASCADE")
        c.execute(File.read(DropSqlFunctions))
      end
    end
  end
end
