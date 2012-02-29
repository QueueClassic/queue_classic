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

  def job_count
    @database.execute('SELECT COUNT(*) FROM queue_classic_jobs')[0].values.first.to_i
  end

  test "transaction should commit" do
    assert_equal true, @database.transaction_idle?
    assert_equal 0, job_count
    @database.transaction do
      assert_equal false, @database.transaction_idle?
      assert_equal 0, job_count
      @database.execute "INSERT INTO queue_classic_jobs (details) VALUES ('test');"
      assert_equal false, @database.transaction_idle?
      assert_equal 1, job_count
    end
    assert_equal true, @database.transaction_idle?
    assert_equal 1, job_count
  end

  test "transaction should rollback if there's an error" do
    assert_raises RuntimeError do
      @database.transaction do
        @database.execute "INSERT INTO queue_classic_jobs (details) VALUES ('test');"
        assert_equal 1, job_count
        raise "force rollback"
      end
    end
    assert_equal 0, job_count
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
