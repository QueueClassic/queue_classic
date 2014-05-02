$: << File.expand_path("lib")
$: << File.expand_path("test")

ENV["DATABASE_URL"] ||= "postgres:///queue_classic_test"

require "queue_classic"
require "stringio"
require "minitest/autorun"

class QCTest < Minitest::Test

  def setup
    init_db
  end

  def teardown
    QC.delete_all
  end

  def init_db
    c = QC::ConnAdapter.new
    c.execute("SET client_min_messages TO 'warning'")
    QC::Setup.drop(c.connection)
    QC::Setup.create(c.connection)
    c.execute(File.read('./test/helper.sql'))
    c.disconnect
  end

  def capture_stderr_output
    original_stderr = $stderr
    $stderr = StringIO.new
    yield
    $stderr.string
  ensure
    $stderr = original_stderr
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
