require 'helper'
context 'ConnectionTest' do
  setup do
    @conn = QueueClassic::Connection.new( database_url )
  end

  teardown do
    @conn.disconnect
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

end
