require File.expand_path("../helper.rb", __FILE__)

class TestNotifier
  def self.deliver(args={})
  end
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
    QC.enqueue("TestNotifier.deliver")
    worker = TestWorker.new("queue_classic_jobs", 1, false, false, 1)
    assert_equal(1, QC.count)
    worker.work
    assert_equal(0, QC.count)
    assert_equal(0, worker.failed_count)
  end

  def test_failed_job
    QC.enqueue("TestNotifier.no_method")
    worker = TestWorker.new("queue_classic_jobs", 1, false, false, 1)
    worker.work
    assert_equal(1, worker.failed_count)
  end

  def test_worker_ueses_one_conn
    QC.enqueue("TestNotifier.deliver")
    worker = TestWorker.new("queue_classic_jobs", 1, false, false, 1)
    worker.work
    assert_equal(
      1,
      QC::Conn.execute("SELECT count(*) from pg_stat_activity")["count"].to_i,
      "Multiple connections -- Are there other connections in other terminals?"
    )
  end

end
