# frozen_string_literal: true

require File.expand_path("../../helper.rb", __FILE__)

class QueueClassicTest < QCTest
  def before_teardown
    ActiveRecord.send :remove_const, :Base
    Object.send :remove_const, :ActiveRecord

    QC.default_conn_adapter = @original_conn_adapter
  end

  def test_lock_with_active_record_timestamp_type_cast
    # Insert an unlocked job
    p_queue = QC::Queue.new("priority_queue")
    conn_adapter = Minitest::Mock.new
    conn_adapter.expect(:execute, {"id" => '1', "q_name" => 'test', "method" => "Kernel.puts", "args" => "[]", "scheduled_at" => Time.now}, [String, String])
    QC.default_conn_adapter = conn_adapter
    assert_equal(p_queue.lock, {})
  end
end
