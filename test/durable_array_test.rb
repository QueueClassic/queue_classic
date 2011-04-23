require File.expand_path("../helper.rb", __FILE__)

context "QC::DurableArray" do

  setup do
    @database = QC::Database.new
    @database.drop_table
    @database.init_db
    @array = QC::DurableArray.new(@database)
  end

  teardown do
    @database.disconnect
  end

  test "decode json into hash" do
    @array << {"test" => "ok"}
    assert_equal({"test" => "ok"}, @array.first.details)
  end

  test "count returns number of rows" do
    @array << {"test" => "ok"}
    assert_equal 1, @array.count
    @array << {"test" => "ok"}
    assert_equal 2, @array.count
  end

  test "first returns first job" do
    job = {"job" => "one"}
    @array << job
    assert_equal job, @array.first.details
  end

  test "first returns first job when many are in the array" do
    @array << {"job" => "one"}
    @array << {"job" => "two"}
    assert_equal({"job" => "one"}, @array.first.details)
  end

  test "find_many returns empty array when nothing is found" do
    assert_equal([], @array.find_many {"select * from queue_classic_jobs"})
  end

  test "delete removes job from the array" do
    @array << {"job" => "one"}
    job = @array.first

    assert_equal( {"job" => "one"}, job.details)

    assert_equal(1,@array.count)
    @array.delete(job)
    assert_equal(0,@array.count)
  end

  test "delete returns job after delete" do
    @array << {"job" => "one"}
    job = @array.first

    assert_equal({"job" => "one"}, job.details)

    res = @array.delete(job)
    assert_equal({"job" => "one"}, res.details)
  end

  test "each yields the details for each job" do
    @array << {"job" => "one"}
    @array << {"job" => "two"}
    results = []
    @array.each {|v| results << v.details}
    assert_equal([{"job" => "one"},{"job" => "two"}], results)
  end

  test "connection build db connection from uri" do
    a = QC::Database.new("postgres://ryandotsmith:@localhost/queue_classic_test")
    assert_equal "ryandotsmith", a.connection.user
    assert_equal "localhost", a.connection.host
    assert_equal "queue_classic_test", a.connection.db
  end

  test "seach" do
    @array << {"job" => "A.signature"}
    jobs = @array.search_details_column("A.signature")
    assert_equal "A.signature", jobs.first.signature
  end

  test "seach when data will not match" do
    @array << {"job" => "A.signature"}
    jobs = @array.search_details_column("B.signature")
    assert_equal [], jobs
  end
end
