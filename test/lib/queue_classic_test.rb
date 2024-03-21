# frozen_string_literal: true

require File.expand_path("../../helper.rb", __FILE__)

class QueueClassicTest < QCTest
  def test_only_delegate_calls_to_queue_it_understands
    e = assert_raises(NoMethodError) do
      QC.probably_not
    end

    if RUBY_VERSION >= "3.3.0"
      assert_equal "undefined method `probably_not' for module QC", e.message
    else
      assert_equal "undefined method `probably_not' for QC", e.message
    end
  end

  def test_default_conn_adapter_default_value
    assert(QC.default_conn_adapter.is_a?(QC::ConnAdapter))
  end

  def test_assigning_a_default_conn_adapter
    original_conn_adapter = QC.default_conn_adapter
    connection = QC::ConnAdapter.new
    QC.default_conn_adapter = connection
    assert_equal(QC.default_conn_adapter, connection)
  ensure
    QC.default_conn_adapter = original_conn_adapter
  end

  def test_unlock_jobs_of_dead_workers
    # Insert a locked job
    adapter = QC::ConnAdapter.new
    query = "INSERT INTO #{QC.table_name} (q_name, method, args, locked_by, locked_at) VALUES ('whatever', 'Kernel.puts', '[\"ok?\"]', 0, (CURRENT_TIMESTAMP))"
    adapter.execute(query)

    # We should have no unlocked jobs
    query_locked_jobs = "SELECT * FROM #{QC.table_name} WHERE locked_at IS NULL"
    res = adapter.connection.exec(query_locked_jobs)
    assert_equal(0, res.count)

    # Unlock the job
    QC.unlock_jobs_of_dead_workers

    # We should have an unlocked job now
    res = adapter.connection.exec(query_locked_jobs)
    assert_equal(1, res.count)
  end
end
