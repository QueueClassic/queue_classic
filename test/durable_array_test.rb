require File.expand_path("../helper.rb", __FILE__)

class DurableArrayTest < MiniTest::Unit::TestCase
  include DatabaseHelpers

  def test_head_decodes_json
    clean_database
    array = QC::DurableArray.new(:dbname => "queue_classic_test")

    array << {"test" => "ok"}
    assert_equal({"test" => "ok"}, array.head.details)
  end

  def test_count_returns_number_of_rows
    clean_database
    array = QC::DurableArray.new(:dbname => "queue_classic_test")

    array << {"test" => "ok"}
    assert_equal 1, array.count
    array << {"test" => "ok"}
    assert_equal 2, array.count
  end

  def test_head_returns_first_job
    clean_database
    array = QC::DurableArray.new(:dbname => "queue_classic_test")

    job = {"job" => "one"}
    array << job
    assert_equal job, array.head.details
  end

  def test_head_returns_first_job_when_many_are_in_array
    clean_database
    array = QC::DurableArray.new(:dbname => "queue_classic_test")

    array << {"job" => "one"}
    array << {"job" => "two"}
    assert_equal({"job" => "one"}, array.head.details)
  end

  def test_delete_removes_job_from_array
    clean_database
    array = QC::DurableArray.new(:dbname => "queue_classic_test")

    array << {"job" => "one"}
    assert_equal( {"job" => "one"}, array.head.details)
    array.delete(array.head)
    assert_nil array.head
  end

  def test_delete_returns_job_after_delete
    clean_database
    array = QC::DurableArray.new(:dbname => "queue_classic_test")

    array << {"job" => "one"}
    assert_equal({"job" => "one"}, array.head.details)

    res = array.delete(array.head)
    assert_nil(array.head)
    assert_equal({"job" => "one"}, res.details)
  end

  def test_each_yields_the_details_for_each_job
    clean_database
    array = QC::DurableArray.new(:dbname => "queue_classic_test")

    array << {"job" => "one"}
    array << {"job" => "two"}
    results = []
    array.each {|v| results << v}
    assert_equal([{"job" => "one"},{"job" => "two"}], results)
  end

end
