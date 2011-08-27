require File.expand_path("../helper.rb", __FILE__)

context "DatabaseTest" do

  setup do
    @database = init_db
  end

  teardown do
    @database.disconnect
  end

  test "drain_notify clears all of the notifications" do
    @database.execute("NOTIFY queue_classic_jobs")
    assert_nil @database.drain_notify

    @database.listen
    @database.execute("NOTIFY queue_classic_jobs, 'hello'")
    notify = @database.drain_notify
    assert_equal "queue_classic_jobs", notify[:relname]
    assert_equal "hello", notify[:extra]
    assert_nil @database.drain_notify
  end

end
