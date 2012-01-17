require 'helper'
context 'ConnectionTest' do
  setup do
    setup_db
    @conn = QueueClassic::Connection.new( database_url )
  end

  teardown do
    @conn.disconnect
    teardown_db
  end

  test "execute should return rows" do
    result = @conn.execute 'SELECT 11 foo, 22 bar;'
    assert_equal [{ 'foo' => '11', 'bar' => '22' }], result.to_a
  end

  test "execute should raise an error on failure" do
    assert_raises PGError do
      @conn.execute "SELECT unknown FROM missing"
    end
  end

  test "execute should accept parameters" do
    result = @conn.execute 'SELECT $2::int b, $1::int a, $1::int + $2::int c;', 123, '456'
    assert_equal [{"a"=>"123", "b"=>"456", "c"=>"579"}], result.to_a
  end

  test "connection sets the search path so the queue classic schema is at the front" do
    result = @conn.execute 'SHOW search_path'
    assert_equal [{ "search_path" => "queue_classic, public" }], result.to_a
  end

  test "connection can see if a schema exists" do
    assert @conn.schema_exist?
    refute @conn.schema_exist?( "doesnotexist" )
  end

  test "connection raises an error if the schema does not exist" do
    assert_raises QueueClassic::Error do
      QueueClassic::Connection.new( database_url, "qc" )
    end
  end

  test "connection can use an alternative schema" do
    QueueClassic::Bootstrap.setup( database_url, "qc" )
    conn = QueueClassic::Connection.new( database_url, "qc" )
    result = conn.execute 'SHOW search_path'
    assert_equal [{ "search_path" => "qc, public" }], result.to_a
    QueueClassic::Bootstrap.teardown( database_url, "qc" )
  end

end
