# frozen_string_literal: true

require 'helper'
require 'active_record'

class QueueClassicActiverecordIntegrationTest < QCTest
  def setup
    super
    reset_globals
    ActiveRecord::Base.establish_connection "#{ENV["DATABASE_URL"]}?pool=1"
  end

  def teardown
    super
  end

  def test_connection_not_returned_to_pool
    take_connection_until_checked = Mutex.new
    conn_adapter_ready = Queue.new
    connection_from_adapter = nil
    take_connection_until_checked.synchronize do
      Thread.new do
        with_env 'QC_RAILS_DATABASE' => 'true' do
          conn_adapter_ready.push QC.default_conn_adapter.connection
        end
        take_connection_until_checked.synchronize {}
        ActiveRecord::Base.clear_active_connections!
      end

      connection_from_adapter = conn_adapter_ready.pop

      ActiveRecord::Base.connection_pool.reap

      # Pool now has no free connections available
      assert_raises(ActiveRecord::ConnectionTimeoutError) do
        ActiveRecord::Base.connection_pool.checkout 0.1
      end
    end
  end
end
