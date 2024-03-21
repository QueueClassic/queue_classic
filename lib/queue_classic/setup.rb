# frozen_string_literal: true

module QC
  module Setup
    Root = File.expand_path("../..", File.dirname(__FILE__))
    SqlFunctions = File.join(Root, "/sql/ddl.sql")
    CreateTable = File.join(Root, "/sql/create_table.sql")
    DropSqlFunctions = File.join(Root, "/sql/drop_ddl.sql")
    UpgradeTo_3_0_0 = File.join(Root, "/sql/update_to_3_0_0.sql")
    DowngradeFrom_3_0_0 = File.join(Root, "/sql/downgrade_from_3_0_0.sql")
    UpgradeTo_3_1_0 = File.join(Root, "/sql/update_to_3_1_0.sql")
    DowngradeFrom_3_1_0 = File.join(Root, "/sql/downgrade_from_3_1_0.sql")
    UpgradeTo_4_0_0 = File.join(Root, "/sql/update_to_4_0_0.sql")
    DowngradeFrom_4_0_0 = File.join(Root, "/sql/downgrade_from_4_0_0.sql")

    def self.create(c = QC::default_conn_adapter.connection)
      conn = QC::ConnAdapter.new(connection: c)
      conn.execute(File.read(CreateTable))
      conn.execute(File.read(SqlFunctions))
      conn.disconnect if c.nil? #Don't close a conn we didn't create.
    end

    def self.drop(c = QC::default_conn_adapter.connection)
      conn = QC::ConnAdapter.new(connection: c)
      conn.execute("DROP TABLE IF EXISTS queue_classic_jobs CASCADE")
      conn.execute(File.read(DropSqlFunctions))
      conn.disconnect if c.nil? #Don't close a conn we didn't create.
    end

    def self.update(c = QC::default_conn_adapter.connection)
      conn = QC::ConnAdapter.new(connection: c)
      conn.execute(File.read(UpgradeTo_3_0_0))
      conn.execute(File.read(UpgradeTo_3_1_0))
      conn.execute(File.read(UpgradeTo_4_0_0))
      conn.execute(File.read(DropSqlFunctions))
      conn.execute(File.read(SqlFunctions))
    end

    def self.update_to_3_0_0(c = QC::default_conn_adapter.connection)
      conn = QC::ConnAdapter.new(connection: c)
      conn.execute(File.read(UpgradeTo_3_0_0))
      conn.execute(File.read(DropSqlFunctions))
      conn.execute(File.read(SqlFunctions))
    end

    def self.downgrade_from_3_0_0(c = QC::default_conn_adapter.connection)
      conn = QC::ConnAdapter.new(connection: c)
      conn.execute(File.read(DowngradeFrom_3_0_0))
    end

    def self.update_to_3_1_0(c = QC::default_conn_adapter.connection)
      conn = QC::ConnAdapter.new(connection: c)
      conn.execute(File.read(UpgradeTo_3_1_0))
      conn.execute(File.read(DropSqlFunctions))
      conn.execute(File.read(SqlFunctions))
    end

    def self.downgrade_from_3_1_0(c = QC::default_conn_adapter.connection)
      conn = QC::ConnAdapter.new(connection: c)
      conn.execute(File.read(DowngradeFrom_3_1_0))
    end

    def self.update_to_4_0_0(c = QC::default_conn_adapter.connection)
      conn = QC::ConnAdapter.new(connection: c)
      conn.execute(File.read(UpgradeTo_4_0_0))
      conn.execute(File.read(DropSqlFunctions))
      conn.execute(File.read(SqlFunctions))
    end

    def self.downgrade_from_4_0_0(c = QC::default_conn_adapter.connection)
      conn = QC::ConnAdapter.new(connection: c)
      conn.execute(File.read(DowngradeFrom_4_0_0))
    end
  end
end
