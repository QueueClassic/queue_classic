require File.expand_path("../helper.rb", __FILE__)

class TestNotifier
  def self.deliver(args={})
  end
end

class WorkerTest < MiniTest::Unit::TestCase
  include DatabaseHelpers

  def test_working_a_job
    set_data_store
    clean_database

    QC.enqueue "TestNotifier.deliver", {}
    worker = QC::Worker.new

    assert_equal(1, QC.queue_length)
    worker.work
    assert_equal(0, QC.queue_length)
  end

end

