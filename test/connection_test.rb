require 'helper'
context 'Connection' do
  setup do
    setup_db
    @conn = QueueClassic::Connection.new( database_url )
    @recv = QueueClassic::Connection.new( database_url )
  end

  teardown do
    @conn.close
    @recv.close
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

  test "can send a notification on one connection and receive it on another" do
    @recv.listen( 'boom' )
    @conn.notify( 'boom', 'pay attention')
    n = @recv.wait_for_notification(1)
    assert_equal 'boom', n.channel
    assert_equal 'pay attention', n.message
    @recv.unlisten( 'boom' )
  end

  test "can listen on more than one channel" do
    @recv.listen( 'c1' )
    @recv.listen( 'c2' )

    @conn.notify( 'c1', "c1 message" )
    @conn.notify( 'c2', "c2 message" )

    n1 = @recv.wait_for_notification(1)
    assert_equal 'c1', n1.channel
    assert_equal 'c1 message', n1.message

    n2 = @recv.wait_for_notification(1)
    assert_equal 'c2', n2.channel
    assert_equal 'c2 message', n2.message
  end

  test "it can return all pending notifications from the channel" do
    @recv.listen( 'c1' )

    10.times do |x|
      @conn.notify( 'c1', "msg #{x}")
    end
    c = @recv.notifications( true )
    assert_equal 10, c.size
  end

  test "it can iterate over all the notifcations in the channel" do
    @recv.listen( 'c1' )
    10.times do |x|
      @conn.notify( 'c1', "msg #{x}" )
    end

    count = 0
    @recv.each_notification(true) do |n|
      assert_equal 'c1', n.channel
      count += 1
    end
    assert_equal 10, count
  end
end
