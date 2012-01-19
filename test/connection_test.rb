require 'helper'
context 'Connection' do
  setup do
    setup_db
    @conn = QueueClassic::Connection.new( database_url )
  end

  teardown do
    @conn.close
    teardown_db
  end

  test "executing a non-query statement returns an empty array" do
    result = @conn.execute "create temporary table foo(i int)"
    assert result.empty?
  end

  test "execute should return a single row" do
    result = @conn.execute 'SELECT 11 foo, 22 bar;'
    assert_equal [{ 'foo' => '11', 'bar' => '22' }], result
  end

  test "execute should return multiple rows" do
    result = @conn.execute 'SELECT * FROM generate_series(2,4) AS gs'
    assert_equal 3, result.size
    assert_equal [ { "gs" => "2" },  {"gs" => "3" }, {"gs"=> "4"} ], result
  end

  test "execute should raise an error on failure" do
    assert_raises PGError do
      @conn.execute "SELECT unknown FROM missing"
    end
  end

  test "execute should accept parameters" do
    result = @conn.execute 'SELECT $2::int b, $1::int a, $1::int + $2::int c;', 123, '456'
    assert_equal [{"a"=>"123", "b"=>"456", "c"=>"579"}], result
  end

  test "connection can see if a schema exists" do
    assert @conn.schema_exist?( 'public' )
    refute @conn.schema_exist?( "doesnotexist" )
  end

end
