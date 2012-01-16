require 'helper'

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
  def initialize
    @failed_count = 0
    super
  end
  def handle_failure(job,e)
    @failed_count += 1
  end
end

context "Worker" do

  setup do
    @database = init_db
    @worker = TestWorker.new
  end

  teardown do
    @database.disconnect
  end

  test "working a job" do
    QC::Queue.enqueue "TestNotifier.deliver", {}

    assert_equal(1, QC::Queue.length)
    @worker.work
    assert_equal(0, QC::Queue.length)
    assert_equal(0, @worker.failed_count)
  end

  test "resuce failed job" do
    QC::Queue.enqueue "TestNotifier.no_method", {}

    @worker.work
    assert_equal 1, @worker.failed_count
  end

  test "only makes one connection" do
    QC.enqueue "TestNotifier.deliver", {}
    @worker.work
    assert_equal 1, @database.execute("SELECT count(*) from pg_stat_activity")[0]["count"].to_i,
      "Multiple connections -- Are there other connections in other terminals?"
  end

end
