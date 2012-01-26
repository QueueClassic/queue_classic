require 'helper'
require 'queue_classic/bootstrap'

context 'Bootstrap' do
  setup do
    @boot = QueueClassic::Bootstrap.new( 'postgres:///queue_classic_test', 'qc' )
  end

  teardown do
    if @boot.schema_exist?( 'qc' ) then
      @boot.teardown
    end
    @boot.close
  end

  test "can setup the tables and functions into a schema" do
    boot = QueueClassic::Bootstrap.setup( 'postgres:///queue_classic_test', 'qc' )
    assert boot.schema_exist?( 'qc' )
  end

  test "can teardown the tables and functions in the schema" do
    refute @boot.schema_exist?( 'qc' )
    @boot.setup
    assert @boot.schema_exist?( 'qc' )
    assert @boot.table_exist?( 'qc', 'messages' )
    @boot.teardown
    refute @boot.schema_exist?( 'qc' )
  end
end
