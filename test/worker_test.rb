require File.expand_path("../helper.rb", __FILE__)

class TestNotifier
  def self.deliver(args={})
  end
end

# This not only allows me to test what happens
# when a failure occures but it also demonstrates
# how to override the worker to handle failures the way
# you want.
class TestWorker < QC::Worker
  attr_accessor :failed_count
  def initialize
    @failed_count = 0
    super
  end
  def handle_failure(job,e)
    @failed_count += 1
  end
end

class WorkerTest < MiniTest::Unit::TestCase
  include DatabaseHelpers

  def test_working_a_job
    set_data_store
    clean_database

    QC.enqueue "TestNotifier.deliver", {}
    worker = TestWorker.new

    assert_equal(1, QC.queue_length)
    worker.work
    assert_equal(0, QC.queue_length)
    assert_equal(0, worker.failed_count)
  end

  def test_rescue_failed_jobs
    set_data_store
    clean_database

    QC.enqueue "TestNotifier.no_method", {}
    worker = TestWorker.new

    worker.work
    assert_equal 1, worker.failed_count
  end

end
