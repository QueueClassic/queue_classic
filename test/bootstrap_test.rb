require 'helper'
context 'BootstrapTest' do
  setup do
    @boot = QueueClassic::Bootstrap.new( 'postgres:///queue_classic_test', 'qc' )
  end

  teardown do
    if @boot.conn.schema_exist?( 'qc' ) then
      @boot.teardown
    end
  end

  test "can setup the tables and functions into a schema" do
    boot = QueueClassic::Bootstrap.setup( 'postgres:///queue_classic_test', 'qc' )
    assert boot.conn.schema_exist?( 'qc' )
  end

  test "can teardown the tables and functions in the schema" do
    refute @boot.conn.schema_exist?( 'qc' )
    @boot.setup
    assert @boot.conn.schema_exist?( 'qc' )
    @boot.teardown
    refute @boot.conn.schema_exist?( 'qc' )
  end
end
