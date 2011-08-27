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
    @database.drain_notify
    assert   @database.connection.notifies.nil?
  end

end
