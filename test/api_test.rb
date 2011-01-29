require File.expand_path("../helper.rb", __FILE__)

class ApiTest < MiniTest::Unit::TestCase
  include DatabaseHelpers

  def test_enqueue_takes_a_job
    clean_database

    assert_equal 0, QC.queue_length
    res = QC.enqueue "Notifier.send", {}
    assert_equal 1, QC.queue_length
  end
end

