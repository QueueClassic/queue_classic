require File.expand_path("../helper.rb", __FILE__)

class DurableArrayTest < MiniTest::Unit::TestCase
  include DatabaseHelpers

  def setup
    @user = "pmiranda"
    @password = "1234"
    @host = "localhost"
    @database = "queue_classic_test"
  end

  def test_first_decodes_json
    clean_database
    array = QC::DurableArray.new(:database => @database)

    array << {"test" => "ok"}
    assert_equal({"test" => "ok"}, array.first.details)
  end

  def test_count_returns_number_of_rows
    clean_database
    array = QC::DurableArray.new(:database => @database)

    array << {"test" => "ok"}
    assert_equal 1, array.count
    array << {"test" => "ok"}
    assert_equal 2, array.count
  end

  def test_first_returns_fsrst_job
    clean_database
    array = QC::DurableArray.new(:database => @database)

    job = {"job" => "one"}
    array << job
    assert_equal job, array.first.details
  end

  def test_first_returns_first_job_when_many_are_in_array
    clean_database
    array = QC::DurableArray.new(:database => @database)

    array << {"job" => "one"}
    array << {"job" => "two"}
    assert_equal({"job" => "one"}, array.first.details)
  end

  def test_delete_removes_job_from_array
    clean_database
    array = QC::DurableArray.new(:database => @database)

    array << {"job" => "one"}
    job = array.first

    assert_equal( {"job" => "one"}, job.details)
    array.delete(job)
    assert_nil array.first
  end

  def test_delete_returns_job_after_delete
    clean_database
    array = QC::DurableArray.new(:database => @database)

    array << {"job" => "one"}
    job = array.first

    assert_equal({"job" => "one"}, job.details)

    res = array.delete(job)
    assert_nil(array.first)
    assert_equal({"job" => "one"}, res.details)
  end

  def test_each_yields_the_details_for_each_job
    clean_database
    array = QC::DurableArray.new(:database => @database)

    array << {"job" => "one"}
    array << {"job" => "two"}
    results = []
    array.each {|v| results << v}
    assert_equal([{"job" => "one"},{"job" => "two"}], results)
  end

  def test_connection_builds_db_connection_for_uri
    array = QC::DurableArray.new(:database => "postgres://#{@user}:#{@password}@#{@host}/#{@database}")
    assert_equal @user, array.connection.user
    assert_equal @host, array.connection.host
    assert_equal @database, array.connection.db
  end

  def test_connection_builds_db_connection_for_database
    array = QC::DurableArray.new(:database => @database)

    # FIXME not everyone will have a postgres user named: ryandotsmith
    assert_equal @user, array.connection.user
    assert_equal @database, array.connection.db
  end

end

