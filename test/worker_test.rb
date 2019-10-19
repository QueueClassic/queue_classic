# frozen_string_literal: true

require_relative 'helper'

module TestObject
  extend self
  def no_args; return nil; end
  def one_arg(a); return a; end
  def two_args(a,b); return [a,b]; end
  def forty_two; OpenStruct.new(number: 42); end
end

# This not only allows me to test what happens
# when a failure occurs but it also demonstrates
# how to override the worker to handle failures the way
# you want.
class TestWorker < QC::Worker
  attr_accessor :failed_count

  def initialize(args={})
    super(args.merge(:connection => QC.default_conn_adapter.connection))
    @failed_count = 0
  end

  def handle_failure(job,e)
    @failed_count += 1
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

  def test_worker_reuses_conn
    QC.enqueue("TestObject.no_args")
    count = QC.default_conn_adapter.execute("SELECT count(*) from pg_stat_activity where datname = current_database()")["count"].to_i;
    worker = TestWorker.new
    worker.work

    new_count = QC.default_conn_adapter.execute("SELECT count(*) from pg_stat_activity where datname = current_database()")["count"].to_i;
    assert(
      new_count == count,
      "Worker should not initialize new connections to #{ QC.default_conn_adapter.send(:db_url) }."
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
      assert_raises(ArgumentError) do
        worker = QC::Worker.new
        QC.enqueue("TestObject.no_args")
        worker.lock_job
      end
    end
  end

  def test_worker_unlocks_job_on_signal_exception
    job_details = QC.enqueue("Kernel.eval", "raise SignalException.new('INT')")
    worker = TestWorker.new

    unlocked = nil

    fake_unlock = Proc.new do |job_id|
      if job_id == job_details['id']
        unlocked = true
      end
      original_unlock(job_id)
    end

    stub_any_instance(QC::Queue, :unlock, fake_unlock) do
      begin
        worker.work
      rescue SignalException
      ensure
        assert unlocked, "SignalException failed to unlock the job in the queue."
      end
    end
  end

  def test_worker_unlocks_job_on_system_exit
    job_details = QC.enqueue("Kernel.eval", "raise SystemExit.new")
    worker = TestWorker.new

    unlocked = nil

    fake_unlock = Proc.new do |job_id|
      if job_id == job_details['id']
        unlocked = true
      end
      original_unlock(job_id)
    end

    stub_any_instance(QC::Queue, :unlock, fake_unlock) do
      begin
        worker.work
      rescue SystemExit
      ensure
        assert unlocked, "SystemExit failed to unlock the job in the queue."
      end
    end
  end

  def test_worker_does_not_unlock_jobs_on_syntax_error
    job_details = QC.enqueue("Kernel.eval", "bad syntax")
    worker = TestWorker.new

    unlocked = nil

    fake_unlock = Proc.new do |job_id|
      if job_id == job_details['id']
        unlocked = true
      end
      original_unlock(job_id)
    end

    stub_any_instance(QC::Queue, :unlock, fake_unlock) do
      begin
        errors = capture_stderr_output do
          worker.work
        end
      ensure
        message = ["SyntaxError unexpectedly unlocked the job in the queue."]
        message << "Errors:\n#{errors}" unless errors.empty?
        refute unlocked, message.join("\n")
      end
    end
  end

  def test_worker_does_not_unlock_jobs_on_load_error
    job_details = QC.enqueue("Kernel.eval", "require 'not_a_real_file'")
    worker = TestWorker.new

    unlocked = nil

    fake_unlock = Proc.new do |job_id|
      if job_id == job_details['id']
        unlocked = true
      end
      original_unlock(job_id)
    end

    stub_any_instance(QC::Queue, :unlock, fake_unlock) do
      begin
        errors = capture_stderr_output do
          worker.work
        end
      ensure
        message = ["LoadError unexpectedly unlocked the job in the queue."]
        message << "Errors:\n#{errors}" unless errors.empty?
        refute unlocked, message.join("\n")
      end
    end
  end

  def test_worker_does_not_unlock_jobs_on_no_memory_error
    job_details = QC.enqueue("Kernel.eval", "raise NoMemoryError.new")
    worker = TestWorker.new

    unlocked = nil

    fake_unlock = Proc.new do |job_id|
      if job_id == job_details['id']
        unlocked = true
      end
      original_unlock(job_id)
    end

    stub_any_instance(QC::Queue, :unlock, fake_unlock) do
      begin
        errors = capture_stderr_output do
          worker.work
        end
      ensure
        message = ["NoMemoryError unexpectedly unlocked the job in the queue."]
        message << "Errors:\n#{errors}" unless errors.empty?
        refute unlocked, message.join("\n")
      end
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
