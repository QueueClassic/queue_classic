require File.expand_path("../../helper.rb", __FILE__)

class QueueClassicRailsConnectionTest < QCTest
  def before_setup
    Object.send :const_set, :ActiveRecord, Module.new
    ActiveRecord.const_set :Base, Module.new

    @original_conn_adapter = QC.default_conn_adapter
    QC.default_conn_adapter = nil
  end

  def after_teardown
    ActiveRecord.send :remove_const, :Base
    Object.send :remove_const, :ActiveRecord

    QC.default_conn_adapter = @original_conn_adapter
  end

  def test_uses_active_record_connection_if_exists
    connection = get_connection
    assert connection.verify
  end

  def test_does_not_use_active_record_connection_if_env_var_set
    with_env 'QC_RAILS_DATABASE' => 'false' do
      connection = get_connection
      assert_raises(MockExpectationError) { connection.verify }
    end
  end

  private
  def get_connection
    connection = Minitest::Mock.new
    connection.expect(:raw_connection, QC::ConnAdapter.new.connection)

    ActiveRecord::Base.define_singleton_method(:connection) do
      connection
    end

    QC.default_conn_adapter
    connection
  end
end
