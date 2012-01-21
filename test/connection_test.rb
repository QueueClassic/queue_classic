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

  test "raises an error on failure to connect" do
    assert_raises PGError do
      QueueClassic::Connection.new( "postgresql:///does-not-exist" )
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

  test "connection knows its search path" do
    assert_equal '"$user",public', @conn.search_path
  end

  test "connection can set its search_path" do
    assert_equal '"$user",public', @conn.search_path
    @conn.search_path = "queue_classic"
    assert_equal "queue_classic", @conn.search_path
  end

  test "conneciton knows its application name" do
    assert_equal '', @conn.application_name
  end

  test 'connection can set its application name' do
    assert_equal '', @conn.application_name
    @conn.application_name = 'foo'
    assert_equal 'foo', @conn.application_name
  end

  test "connection can generate a unique applciation name" do
    @conn.search_path = 'queue_classic'
    app_name = @conn.apply_application_name( 'app-uid' )
    row = @conn.execute("SHOW application_name")
    assert_match /app-uid-(\d+)/, row.first['application_name']
  end

end
