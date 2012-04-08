$: << File.expand_path("lib")
$: << File.expand_path("test")

ENV["DATABASE_URL"] ||= "postgres:///queue_classic_test"

require "queue_classic"
require "minitest/unit"
MiniTest::Unit.autorun

class QCTest < MiniTest::Unit::TestCase

  def setup
    init_db
  end

  def teardown
    QC.delete_all
  end

  def init_db(table_name="queue_classic_jobs")
    QC::Conn.execute("SET client_min_messages TO 'warning'")
    QC::Conn.execute("DROP TABLE IF EXISTS #{table_name} CASCADE")
    QC::Conn.execute("CREATE TABLE #{table_name} (id serial, q_name varchar(255), method varchar(255), args text, locked_at timestamptz)")
    QC::Queries.load_functions
    QC::Conn.disconnect
  end

end
