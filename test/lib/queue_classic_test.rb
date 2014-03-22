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
end
