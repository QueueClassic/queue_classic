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
    worker.work
    assert_equal(1, worker.failed_count)
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
    p_queue.enqueue("TestObject.two_args", "1", 2)
    worker = TestWorker.new(q_name: "priority_queue", listening_worker: true)
    r = worker.work
    assert_equal(["1", 2], r)
    assert_equal(0, worker.failed_count)
  end

  def test_worker_ueses_one_conn
    QC.enqueue("TestObject.no_args")
    worker = TestWorker.new
    worker.work
    assert_equal(
      1,
      QC::Conn.execute("SELECT count(*) from pg_stat_activity")["count"].to_i,
      "Multiple connections -- Are there other connections in other terminals?"
    )
  end

end
