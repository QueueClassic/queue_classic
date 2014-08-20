require File.expand_path("../../helper.rb", __FILE__)

class QueueClassicTest < QCTest
  def test_default_conn_adapter_default_value
    assert(QC.default_conn_adapter.is_a?(QC::ConnAdapter))
  end

  def test_default_conn_adapter=
    connection = QC::ConnAdapter.new
    QC.default_conn_adapter = connection
    assert_equal(QC.default_conn_adapter, connection)
  end

  def test_unlock_jobs_of_dead_workers
    # Insert a locked job
    adapter = QC::ConnAdapter.new
    query = "INSERT INTO #{QC::TABLE_NAME} (q_name, method, args, locked_by, locked_at) VALUES ('whatever', 'Kernel.puts', '[\"ok?\"]', 0, (CURRENT_TIMESTAMP))"
    adapter.execute(query)

    # We should have no unlocked jobs
    query_locked_jobs = "SELECT * FROM #{QC::TABLE_NAME} WHERE locked_at IS NULL"
    res = adapter.connection.exec(query_locked_jobs)
    assert_equal(0, res.count)

    # Unlock the job
    QC.unlock_jobs_of_dead_workers

    # We should have an unlocked job now
    res = adapter.connection.exec(query_locked_jobs)
    assert_equal(1, res.count)
  end
end
