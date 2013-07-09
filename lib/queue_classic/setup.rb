module QC
  module Setup
    Root = File.expand_path("../..", File.dirname(__FILE__))
    SqlFunctions = File.join(Root, "/sql/ddl.sql")
    CreateTable = File.join(Root, "/sql/create_table.sql")

    def self.create
      Conn.transaction do
        Conn.execute(File.read(CreateTable))
        Conn.execute(File.read(SqlFunctions))
      end
    end

    def self.drop
      Conn.execute("DROP TABLE IF EXISTS queue_classic_jobs CASCADE")
    end
  end
end
