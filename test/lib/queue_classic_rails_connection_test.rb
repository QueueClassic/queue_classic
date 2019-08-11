# frozen_string_literal: true

require File.expand_path("../../helper.rb", __FILE__)

class QueueClassicRailsConnectionTest < QCTest
  # Stubs ActiveRecord::Base with empty module. Works if real
  # ActiveRecord is loaded too, restoring it when unstubbing.
  class StubActiveRecord
    def stub
      stub_module
      stub_base
    end

    def unstub
      unstub_base
      unstub_module
    end

    private

    def stub_module
      unless Object.const_defined? :ActiveRecord
        Object.send :const_set, :ActiveRecord, Module.new
        @module_stubbed = true
      else
        @module_stubbed = false
      end
    end

    def unstub_module
      if @module_stubbed
        Object.send :remove_const, :ActiveRecord
      end
    end

    def stub_base
      if Object.const_defined? 'ActiveRecord::Base'
        @activerecord_orig = ActiveRecord::Base
        ActiveRecord.send :remove_const, :Base
      else
        @activerecord_orig = nil
      end
      ActiveRecord.const_set :Base, Module.new
    end

    def unstub_base
      ActiveRecord.send :remove_const, :Base
      if @activerecord_orig
        ActiveRecord.send :const_set, :Base, @activerecord_orig
      end
    end
  end

  def setup
    super
    @active_record_stub = StubActiveRecord.new
    @active_record_stub.stub
    @original_conn_adapter = QC.default_conn_adapter
    QC.default_conn_adapter = nil
  end

  def teardown
    @active_record_stub.unstub
    QC.default_conn_adapter = @original_conn_adapter
    super
  end

  def test_uses_active_record_connection_if_exists
    connection = with_env 'QC_RAILS_DATABASE' => nil do
      get_connection
    end
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
