module QC
  module Setup
    def self.create
      Conn.transaction do
        Conn.execute(File.read(CreateTable))
        Conn.execute(File.read(SqlFunctions))
      end
    end

    def self.drop
      Conn.transaction do
        Conn.execute(File.read(DropTable))
        Conn.execute(File.read(DropSqlFunctions))
      end
    end
  end
end
