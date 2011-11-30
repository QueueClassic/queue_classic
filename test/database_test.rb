require File.expand_path("../helper.rb", __FILE__)

context "DatabaseTest" do

  setup do
    @database = init_db
  end

  teardown do
    @database.disconnect
  end

  test "drain_notify clears all of the notifications" do
    @database.listen
    @database.execute("NOTIFY queue_classic_jobs, 'hello'")

    assert ! @database.connection.notifies.nil?
    assert   @database.connection.notifies.nil?

    @database.execute("NOTIFY queue_classic_jobs, 'hello'")
    @database.execute("NOTIFY queue_classic_jobs, 'hello'")
    @database.execute("NOTIFY queue_classic_jobs, 'hello'")

    @database.drain_notify
    assert   @database.connection.notifies.nil?
  end

  test "execute should return rows" do
    result = @database.execute 'SELECT 11 foo, 22 bar;'
    assert_equal [{'foo'=>'11', 'bar'=>'22'}], result.to_a
  end

  test "should raise error on failure" do
    assert_raises PGError do
      @database.execute 'SELECT unknown FROM missing;'
    end
  end

  test "execute should accept parameters" do
    result = @database.execute 'SELECT $2::int b, $1::int a, $1::int + $2::int c;', 123, '456'
    assert_equal [{"a"=>"123", "b"=>"456", "c"=>"579"}], result.to_a
  end

end
