$: << File.expand_path("lib")
$: << File.expand_path("test")

ENV["DATABASE_URL"] ||= "postgres:///queue_classic_test"

require "queue_classic"
require "stringio"
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
    QC::Setup.drop
    QC::Setup.create
    QC::Conn.execute(<<EOS)
DO $$
-- Set initial sequence to a large number to test the entire toolchain
-- works on integers with higher bits set.
DECLARE
    quoted_name text;
    quoted_size text;
BEGIN
    -- Find the name of the relevant sequence.
    --
    -- pg_get_serial_sequence quotes identifiers as part of its
    -- behavior.
    SELECT name
    INTO STRICT quoted_name
    FROM pg_get_serial_sequence('queue_classic_jobs', 'id') AS name;

    -- Don't quote, because ALTER SEQUENCE RESTART doesn't like
    -- general literals, only unquoted numeric literals.
    SELECT pow(2, 34)::text AS size
    INTO STRICT quoted_size;

    EXECUTE 'ALTER SEQUENCE ' || quoted_name ||
        ' RESTART ' || quoted_size || ';';
END;
$$;
EOS
    QC::Conn.disconnect
  end

  def capture_debug_output
    original_debug = ENV['DEBUG']
    original_stdout = $stdout

    ENV['DEBUG'] = "true"
    $stdout = StringIO.new
    yield
    $stdout.string
  ensure
    ENV['DEBUG'] = original_debug
    $stdout = original_stdout
  end

end
