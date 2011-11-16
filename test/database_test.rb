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

end

# using minitest/spec
describe QC::Database do

  describe ".sql_functions" do
    it "returns the necessary functions" do
      subject = QC::Database.sql_functions
      assert_equal 2, subject.length
      assert_match /USING unlocked/, subject['lock_head(tname name, top_boundary integer)']
      assert_match /RETURN QUERY EXECUTE .SELECT . FROM lock_head/, subject['lock_head(tname varchar)']
    end
  end

end
