require File.expand_path("../helper.rb", __FILE__)
require File.expand_path("../../lib/queue_classic/test_helper.rb", __FILE__)

class TestNotifier
  def self.deliver(args={})
  end
end

context "TestHelper" do
  include QC::TestHelper

  setup do
    @database = init_db
  end

  teardown do
    @database.disconnect
  end

  test "working multiple jobs" do
    QC::Queue.enqueue "TestNotifier.deliver", {}
    QC::Queue.enqueue "TestNotifier.deliver", {}

    assert_equal(2, QC::Queue.length)
    work_jobs
    assert_equal(0, QC::Queue.length)
  end

  test "deleting all jobs" do
    QC::Queue.enqueue "TestNotifier.deliver", {}
    QC::Queue.enqueue "TestNotifier.deliver", {}

    assert_equal(2, QC::Queue.length)
    clear_jobs
    assert_equal(0, QC::Queue.length)
  end

end
