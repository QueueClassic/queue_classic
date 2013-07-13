require File.expand_path("../helper.rb", __FILE__)

module TestObject
  extend self
  def no_args; return nil; end
  def one_arg(a); return a; end
  def two_args(a,b); return [a,b]; end
end

# This not only allows me to test what happens
# when a failure occurs but it also demonstrates
# how to override the worker to handle failures the way
# you want.
class TestWorker < QC::Worker
  attr_accessor :failed_count

  def initialize(*args)
    super(*args)
    @failed_count = 0
  end

  def handle_failure(job,e)
    @failed_count += 1
  end
end

class WorkerTest < QCTest

  def setup
    init_db
    @pool = QC::Pool.new
  end

  def teardown
    QC.pool.drain!
    @pool.drain!
  end

  def test_work
    QC.enqueue("TestObject.no_args")
    worker = TestWorker.new(:pool => @pool)
    assert_equal(1, QC.count)
    worker.work
    assert_equal(0, QC.count)
    assert_equal(0, worker.failed_count)
  end

  def test_failed_job
    QC.enqueue("TestObject.not_a_method")
    worker = TestWorker.new(:pool => @pool)
    worker.work
    assert_equal(1, worker.failed_count)
  end

  def test_failed_job_is_logged
    output = capture_debug_output do
      QC.enqueue("TestObject.not_a_method")
      QC::Worker.new(:pool => @pool).work
    end
    expected_output = /lib=queue-classic at=handle_failure job={:id=>"\d+", :method=>"TestObject.not_a_method", :args=>\[\]} error=#<NoMethodError: undefined method `not_a_method' for TestObject:Module>/
    assert_match(expected_output, output, "=== debug output ===\n #{output}")
  end

  def test_log_yield
    output = capture_debug_output do
      QC.log_yield(:action => "test") do
        0 == 1
      end
    end
    expected_output = /lib=queue-classic action=test elapsed=\d*/
    assert_match(expected_output, output, "=== debug output ===\n #{output}")
  end

  def test_log
    output = capture_debug_output do
      QC.log(:action => "test")
    end
    expected_output = /lib=queue-classic action=test/
    assert_match(expected_output, output, "=== debug output ===\n #{output}")
  end

  def test_work_with_no_args
    QC.enqueue("TestObject.no_args")
    worker = TestWorker.new(:pool => @pool)
    r = worker.work
    assert_nil(r)
    assert_equal(0, worker.failed_count)
  end

  def test_work_with_one_arg
    QC.enqueue("TestObject.one_arg", "1")
    worker = TestWorker.new(:pool => @pool)
    r = worker.work
    assert_equal("1", r)
    assert_equal(0, worker.failed_count)
  end

  def test_work_with_two_args
    QC.enqueue("TestObject.two_args", "1", 2)
    worker = TestWorker.new(:pool => @pool)
    r = worker.work
    assert_equal(["1", 2], r)
    assert_equal(0, worker.failed_count)
  end

  def test_work_custom_queue
    p_queue = QC::Queue.new(:name=> "priority_queue")
    p_queue.enqueue("TestObject.two_args", "1", 2)
    worker = TestWorker.new(:pool => @pool, q_name: "priority_queue")
    r = worker.work
    assert_equal(["1", 2], r)
    assert_equal(0, worker.failed_count)
    p_queue.pool.drain!
  end

  def test_worker_listens_on_chan
    p_queue = QC::Queue.new(:name => "priority_queue")
    p_queue.enqueue("TestObject.two_args", "1", 2)
    worker = TestWorker.new(:pool => @pool, q_name: "priority_queue", listening_worker: true)
    r = worker.work
    assert_equal(["1", 2], r)
    assert_equal(0, worker.failed_count)
    p_queue.pool.drain!
  end

  def test_worker_ueses_one_conn
    QC.enqueue("TestObject.no_args")
    worker = TestWorker.new(:pool => @pool)
    worker.work
    s = 'SELECT count(*) from pg_stat_activity where datname=current_database()'
    num_conns = QC.pool.use {|c| c.execute(s)["count"].to_i}
    # One connection for the worker and one for the test.
    assert_equal(2, num_conns,
      "Multiple connections found -- are there open connections to" +
        " #{QC::Conf.db_url} in other terminals?")
  end

end
