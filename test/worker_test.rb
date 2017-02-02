require_relative 'helper'

module TestObject
  extend self
  def no_args; return nil; end
  def one_arg(a); return a; end
  def two_args(a,b); return [a,b]; end
  def many_args(*args); return args; end
  def forty_two; OpenStruct.new(number: 42); end
  def mutate_args_and_fail(numbers)
    numbers.map! {|number| number * 2 }
    raise 'Problem!'
  end
end

# This not only allows me to test what happens
# when a failure occurs but it also demonstrates
# how to override the worker to handle failures the way
# you want.
class TestWorker < QC::Worker
  attr_accessor :failed_count
  attr_accessor :last_failed_job

  def initialize(args={})
    super(args.merge(:connection => QC.default_conn_adapter.connection))
    @failed_count = 0
  end

  def handle_failure(job,e)
    @failed_count += 1
    @last_failed_job = job
    super
  end
end

class WorkerTest < QCTest
  def test_work
    QC.enqueue("TestObject.no_args")
    worker = TestWorker.new
    assert_equal(1, QC.count)
    worker.work
    assert_equal(0, QC.count)
    assert_equal(0, worker.failed_count)
  end

  def test_failed_job
    QC.enqueue("TestObject.not_a_method")
    worker = TestWorker.new
    capture_stderr_output { worker.work }
    assert_equal(1, worker.failed_count)
  end

  def test_handle_failure_gets_original_args
    QC.enqueue("TestObject.mutate_args_and_fail", [1, 2, 3])
    worker = TestWorker.new
    worker.work
    assert_equal([1, 2, 3], worker.last_failed_job[:args].first)
  end

  def test_failed_job_is_logged
    output = capture_stderr_output do
      QC.enqueue("TestObject.not_a_method")
      TestWorker.new.work
    end
    assert(output.include?("#<NoMethodError: undefined method `not_a_method'"))
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
    worker = TestWorker.new
    r = worker.work
    assert_nil(r)
    assert_equal(0, worker.failed_count)
  end

  def test_work_with_one_arg
    QC.enqueue("TestObject.one_arg", "1")
    worker = TestWorker.new
    r = worker.work
    assert_equal("1", r)
    assert_equal(0, worker.failed_count)
  end

  def test_work_with_two_args
    QC.enqueue("TestObject.two_args", "1", 2)
    worker = TestWorker.new
    r = worker.work
    assert_equal(["1", 2], r)
    assert_equal(0, worker.failed_count)
  end

  def test_worker_handles_all_json_type
    args = 1, 2.3, 4e56, "7", [8], {"9" => "10"}
    QC.enqueue("TestObject.many_args", *args)
    worker = TestWorker.new
    r = worker.work
    assert_equal(args, r)
    assert_equal(0, worker.failed_count)
  end

  def test_work_custom_queue
    p_queue = QC::Queue.new("priority_queue")
    p_queue.enqueue("TestObject.two_args", "1", 2)
    worker = TestWorker.new(q_name: "priority_queue")
    r = worker.work
    assert_equal(["1", 2], r)
    assert_equal(0, worker.failed_count)
  end

  def test_worker_listens_on_chan
    p_queue = QC::Queue.new("priority_queue")
    # Use a new connection because the default connection
    # will be locked by the sleeping worker.
    p_queue.conn_adapter = QC::ConnAdapter.new
    # The wait interval is extreme to demonstrate
    # that the worker is in fact being activated by a NOTIFY.
    worker = TestWorker.new(:q_name => "priority_queue", :wait_interval => 100)
    t = Thread.new do
      r = worker.work
      assert_equal(["1", 2], r)
      assert_equal(0, worker.failed_count)
    end
    sleep(0.5) #Give the thread some time to start the worker.
    p_queue.enqueue("TestObject.two_args", "1", 2)
    p_queue.conn_adapter.disconnect
    t.join
  end

  def test_worker_uses_one_conn
    skip "This test is broken and needs to be fixed."

    QC.enqueue("TestObject.no_args")
    worker = TestWorker.new
    worker.work
    assert_equal(
      1,
      QC.default_conn_adapter.execute("SELECT count(*) from pg_stat_activity WHERE datname = current_database()")["count"].to_i,
      "Multiple connections found -- are there open connections to #{ QC.default_conn_adapter.send(:db_url) } in other terminals?"
    )
  end

  def test_worker_can_work_multiple_queues
    p_queue = QC::Queue.new("priority_queue")
    p_queue.enqueue("TestObject.two_args", "1", 2)

    s_queue = QC::Queue.new("secondary_queue")
    s_queue.enqueue("TestObject.two_args", "1", 2)

    worker = TestWorker.new(:q_names => ["priority_queue", "secondary_queue"])

    2.times do
      r = worker.work
      assert_equal(["1", 2], r)
      assert_equal(0, worker.failed_count)
    end
  end

  def test_worker_works_multiple_queue_left_to_right
    l_queue = QC::Queue.new("left_queue")
    r_queue = QC::Queue.new("right_queue")

    3.times { l_queue.enqueue("TestObject.two_args", "1", 2) }
    3.times { r_queue.enqueue("TestObject.two_args", "1", 2) }

    worker = TestWorker.new(:q_names => ["left_queue", "right_queue"])

    worker.work
    assert_equal(2, l_queue.count)
    assert_equal(3, r_queue.count)

    worker.work
    assert_equal(1, l_queue.count)
    assert_equal(3, r_queue.count)
  end

  def test_work_with_more_complex_construct
    QC.enqueue("TestObject.forty_two.number")
    worker = TestWorker.new
    r = worker.work
    assert_equal(42, r)
    assert_equal(0, worker.failed_count)
  end

  def test_init_worker_with_arg
    with_database 'postgres:///invalid' do
      conn = PG::Connection.connect(dbname: 'queue_classic_test')
      QC::Worker.new connection: conn

      conn.close
    end
  end

  def test_init_worker_with_database_url
    with_database ENV['DATABASE_URL'] || ENV['QC_DATABASE_URL'] do
      worker = QC::Worker.new
      QC.enqueue("TestObject.no_args")
      worker.lock_job

      QC.default_conn_adapter.disconnect
    end
  end

  def test_init_worker_without_conn
    with_database nil do
      assert_raises(ArgumentError) { QC::Worker.new }
    end
  end

  private

  def with_database(url)
    original_conn_adapter = QC.default_conn_adapter
    original_database_url = ENV['DATABASE_URL']
    original_qc_database_url = ENV['QC_DATABASE_URL']

    ENV['DATABASE_URL'] = ENV['QC_DATABASE_URL'] = url
    QC.default_conn_adapter = nil
    yield
  ensure
    ENV['DATABASE_URL'] = original_database_url
    ENV['QC_DATABASE_URL'] = original_qc_database_url
    QC.default_conn_adapter = original_conn_adapter
  end
end
