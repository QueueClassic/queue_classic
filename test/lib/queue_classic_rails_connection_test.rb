# frozen_string_literal: true

require File.expand_path("../../helper.rb", __FILE__)

class QueueClassicRailsConnectionTest < QCTest
  def before_setup
    @original_conn_adapter = QC.default_conn_adapter
    QC.default_conn_adapter = nil
  end

  def before_teardown
    ActiveRecord.send :remove_const, :Base
    Object.send :remove_const, :ActiveRecord

    QC.default_conn_adapter = @original_conn_adapter
  end

  def test_uses_active_record_connection_if_exists
    connection = get_connection
    QC.default_conn_adapter.execute('SELECT 1;')
    connection.verify
  end

  def test_does_not_use_active_record_connection_if_env_var_set
    with_env 'QC_RAILS_DATABASE' => 'false' do
      connection = get_connection
      QC.default_conn_adapter.execute('SELECT 1;')
      assert_raises(MockExpectationError) { connection.verify }
    end
  end

  private
  def get_connection
    connection = Minitest::Mock.new
    connection.expect(:raw_connection, QC::ConnAdapter.new(active_record_connection_share: true).connection)

    Object.send :const_set, :ActiveRecord, Module.new
    ActiveRecord.const_set :Base, Module.new
    ActiveRecord::Base.define_singleton_method(:connection) do
      connection
    end

    QC.default_conn_adapter
    connection
  end
end
