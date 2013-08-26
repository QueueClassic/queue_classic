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

    def self.recreate(poll)
      poll.use do |c|
        c.execute <<-SQL
          SELECT q_name, method, args
          INTO TEMPORARY old_queue_classic_jobs
          FROM queue_classic_jobs
        SQL

        drop pool
        create pool

        c.execute <<-SQL
          INSERT INTO queue_classic_jobs (q_name, method, args)
          SELECT q_name, method, args
          FROM old_queue_classic_jobs
        SQL
      end
    end
  end
end
