require 'queue_classic/conn'

module QC
  module Setup
    Root = File.expand_path("../..", File.dirname(__FILE__))
    SqlFunctions = File.join(Root, "/sql/ddl.sql")
    CreateTable = File.join(Root, "/sql/create_table.sql")
    DropSqlFunctions = File.join(Root, "/sql/drop_ddl.sql")

    def self.create(conn=nil)
      conn ||= Conn.new
      conn.execute(File.read(CreateTable))
      conn.execute(File.read(SqlFunctions))
    end

    def self.drop(conn=nil)
      conn ||= Conn.new
      conn.execute("DROP TABLE IF EXISTS queue_classic_jobs CASCADE")
      conn.execute(File.read(DropSqlFunctions))
    end

    def self.upgrade(conn=nil)
      conn ||= Conn.new
      conn.execute(File.read(SqlFunctions))
    end
  end
end
