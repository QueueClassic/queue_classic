require File.expand_path("../helper.rb", __FILE__)

class QueueTest < MiniTest::Unit::TestCase
  include DatabaseHelpers

  def test_queue_is_singleton
    assert_equal QC::Queue, QC::Queue.instance.class
  end

  def test_queue_setup
    QC::Queue.instance.setup :data_store => []
    assert_equal [], QC::Queue.instance.instance_variable_get(:@data)
  end

  def test_queue_length
    QC::Queue.instance.setup :data_store => []
    QC::Queue.instance.enqueue "job","params"

    assert_equal 1, QC::Queue.instance.length
  end

  def test_queue_delete_all
    QC::Queue.instance.setup :data_store => []

    QC::Queue.instance.enqueue "job","params"
    QC::Queue.instance.enqueue "job","params"

    assert_equal 2, QC::Queue.instance.length
    QC::Queue.instance.delete_all
    assert_equal 0, QC::Queue.instance.length
  end

end
